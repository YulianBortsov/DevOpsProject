from flask import Flask, jsonify, request
from flask_cors import CORS 
from sqlalchemy import create_engine, text, Column, Integer, String
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import declarative_base, sessionmaker
from prometheus_flask_exporter import PrometheusMetrics
import os
import time

app = Flask(__name__)
CORS(app)



# Initialize Prometheus metrics
metrics = PrometheusMetrics(app, path='/metrics')

# Static information as metric
metrics.info('app_info', 'Application info', version='1.0.0')

# Database configuration from environment variables
DB_HOST = os.getenv('RDS_HOSTNAME')  # RDS endpoint
DB_PORT = os.getenv('RDS_PORT', '5432')  # RDS port
DB_NAME = os.getenv('RDS_DB_NAME', 'postgres')
DB_USER = os.getenv('RDS_USERNAME')
DB_PASSWORD = os.getenv('RDS_PASSWORD')

# SQLAlchemy database URI for RDS
DATABASE_URI = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Configure the connection pool
engine = create_engine(
    DATABASE_URI,
    pool_size=5,  # Maximum number of permanent connections
    max_overflow=10,  # Maximum number of additional connections when pool_size is reached
    pool_timeout=30,  # Timeout in seconds for getting a connection from the pool
    pool_recycle=3600,  # Recycle connections after 1 hour to handle RDS connection timeouts
    connect_args={
        'connect_timeout': 10  # Connection timeout in seconds
    }
)

# # Database configuration from environment variables
# DB_HOST = os.getenv('DATABASE_HOST', 'web-app-application-postgresql')
# DB_NAME = os.getenv('DATABASE_NAME', 'postgres')
# DB_USER = os.getenv('DATABASE_USER', 'postgres')
# DB_PASSWORD = os.getenv('DATABASE_PASSWORD', 'password')

# # SQLAlchemy database URI
# DATABASE_URI = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"

# # SQLAlchemy engine
# engine = create_engine(DATABASE_URI)
Session = sessionmaker(bind=engine)
Base = declarative_base()

# Custom metrics
from prometheus_client import Counter, Histogram, Gauge

# Counter metrics
items_created = Counter('items_created_total', 'Total number of items created')
items_deleted = Counter('items_deleted_total', 'Total number of items deleted')
items_updated = Counter('items_updated_total', 'Total number of items updated')
db_errors = Counter('db_errors_total', 'Total number of database errors', ['operation'])

# Histogram metrics
db_operation_duration = Histogram(
    'db_operation_duration_seconds', 
    'Time spent executing database operations',
    ['operation'],
    buckets=[0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]
)

# Gauge metrics
db_connection_status = Gauge('db_connection_status', 'Database connection status (1=up, 0=down)')
active_sessions = Gauge('db_active_sessions', 'Number of active database sessions')

# Model definition
class Item(Base):
    __tablename__ = 'items'
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)

# Ensure the database has the table
Base.metadata.create_all(engine)

@app.route('/api/items', methods=['POST'])
@metrics.counter('items_created_count', 'Number of items created')
def create_item():
    data = request.json
    if not data.get('name'):
        return jsonify({"message": "Name is required!"}), 400
    try:
        with db_operation_duration.labels('create').time():
            session = Session()
            active_sessions.inc()
            
            new_item = Item(name=data['name'], description=data.get('description'))
            session.add(new_item)
            session.commit()
            
            item_id = new_item.id
            item_name = new_item.name
            
            session.close()
            active_sessions.dec()
        
        items_created.inc()
        return jsonify({'message': 'Item created successfully!', 'item': {'id': item_id, 'name': item_name}}), 201
    
    except SQLAlchemyError as e:
        db_errors.labels('create').inc()
        if 'session' in locals():
            session.close()
            active_sessions.dec()
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/items', methods=['GET'])
@metrics.counter('items_list_count', 'Number of times items list was requested')
def get_items():
    try:
        with db_operation_duration.labels('read').time():
            session = Session()
            active_sessions.inc()
            
            items = session.query(Item).all()
            result = [{'id': item.id, 'name': item.name, 'description': item.description} for item in items]
            
            session.close()
            active_sessions.dec()
            
        return jsonify(result)
    
    except SQLAlchemyError as e:
        db_errors.labels('read').inc()
        if 'session' in locals():
            session.close()
            active_sessions.dec()
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/items/<int:item_id>', methods=['PUT'])
@metrics.counter('items_updated_count', 'Number of items updated')
def update_item(item_id):
    data = request.json
    try:
        with db_operation_duration.labels('update').time():
            session = Session()
            active_sessions.inc()
            
            item = session.query(Item).get(item_id)
            if not item:
                session.close()
                active_sessions.dec()
                return jsonify({'message': 'Item not found!'}), 404
            
            item.name = data['name']
            item.description = data.get('description', item.description)
            session.commit()
            
            updated_name = item.name
            session.close()
            active_sessions.dec()
        
        items_updated.inc()
        return jsonify({'message': 'Item updated successfully!', 'item': {'id': item_id, 'name': updated_name}})
    
    except SQLAlchemyError as e:
        db_errors.labels('update').inc()
        if 'session' in locals():
            session.close()
            active_sessions.dec()
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/items/<int:item_id>', methods=['DELETE'])
@metrics.counter('items_deleted_count', 'Number of items deleted')
def delete_item(item_id):
    try:
        with db_operation_duration.labels('delete').time():
            session = Session()
            active_sessions.inc()
            
            item = session.query(Item).get(item_id)
            if not item:
                session.close()
                active_sessions.dec()
                return jsonify({'message': 'Item not found!'}), 404
            
            session.delete(item)
            session.commit()
            
            session.close()
            active_sessions.dec()
        
        items_deleted.inc()
        return jsonify({'message': 'Item deleted successfully!'})
    
    except SQLAlchemyError as e:
        db_errors.labels('delete').inc()
        if 'session' in locals():
            session.close()
            active_sessions.dec()
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api')
@metrics.do_not_track()
def check_db_connection():
    try:
        start_time = time.time()
        with engine.connect() as connection:
            result = connection.execute(text('SELECT 1;'))
            for _ in result:
                pass
        
        db_connection_status.set(1)
        latency = time.time() - start_time
        db_operation_duration.labels('connection_check').observe(latency)
        
        return jsonify({
            'status': 'success', 
            'message': 'Database connection is healthy!',
            'latency': f'{latency:.3f} seconds'
        })
    
    except SQLAlchemyError as e:
        db_connection_status.set(0)
        db_errors.labels('connection_check').inc()
        return jsonify({'status': 'error', 'message': str(e)}), 500

# Health check endpoint
@app.route('/api/health')
@metrics.do_not_track()
def health_check():
    try:
        # Quick DB connection check
        with engine.connect() as connection:
            connection.execute(text('SELECT 1;')).fetchone()
        return jsonify({'status': 'healthy', 'database': 'connected'})
    except SQLAlchemyError:
        return jsonify({'status': 'unhealthy', 'database': 'disconnected'}), 503

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
