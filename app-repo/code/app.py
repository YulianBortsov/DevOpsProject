from flask import Flask, jsonify, request
from flask_cors import CORS 
from sqlalchemy import create_engine, text, Column, Integer, String
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import declarative_base, sessionmaker
import os

app = Flask(__name__)
CORS(app)

# Database configuration from environment variables
DB_HOST = os.getenv('DATABASE_HOST', 'web-app-application-postgresql')
DB_NAME = os.getenv('DATABASE_NAME', 'postgres')
DB_USER = os.getenv('DATABASE_USER', 'postgres')
DB_PASSWORD = os.getenv('DATABASE_PASSWORD', 'password')

# SQLAlchemy database URI
DATABASE_URI = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"

# SQLAlchemy engine
engine = create_engine(DATABASE_URI)
Session = sessionmaker(bind=engine)
Base = declarative_base()

# Model definition
class Item(Base):
    __tablename__ = 'items'
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)

# Ensure the database has the table
Base.metadata.create_all(engine)

# Added basic CRUD routes
# POST on /items
@app.route('/api/items', methods=['POST'])
def create_item():
    data = request.json
    try:
        # Create a session
        session = Session()

        # Create a new item
        new_item = Item(name=data['name'], description=data.get('description'))
        
        # Add the new item to the session
        session.add(new_item)
        session.commit()
        
        # Access attributes before closing the session
        item_id = new_item.id
        item_name = new_item.name

        # Close the session
        session.close()

        # Return the response
        return jsonify({'message': 'Item created successfully!', 'item': {'id': item_id, 'name': item_name}}), 201
    except SQLAlchemyError as e:
        # Handle any database errors
        return jsonify({'status': 'error', 'message': str(e)}), 500

# GET on /items
@app.route('/api/items', methods=['GET'])
def get_items():
    try:
        # Create a session
        session = Session()

        # Retrieve all items from the database
        items = session.query(Item).all()

        # Close the session
        session.close()

        # Return the list of items
        return jsonify([{'id': item.id, 'name': item.name, 'description': item.description} for item in items])
    except SQLAlchemyError as e:
        # Handle any database errors
        return jsonify({'status': 'error', 'message': str(e)}), 500

# PUT on /items/<item_id>
@app.route('/api/items/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    data = request.json
    try:
        # Create a session
        session = Session()

        # Find the item by ID
        item = session.query(Item).get(item_id)
        if not item:
            return jsonify({'message': 'Item not found!'}), 404
        
        # Update the item properties
        item.name = data['name']
        item.description = data.get('description', item.description)
        
        # Commit the changes to the database
        session.commit()

        # Access attributes before closing the session
        updated_name = item.name

        # Close the session
        session.close()

        return jsonify({'message': 'Item updated successfully!', 'item': {'id': item.id, 'name': updated_name}})

    except SQLAlchemyError as e:
        # Handle any database errors
        return jsonify({'status': 'error', 'message': str(e)}), 500

# DELETE on /items/<item_id>
@app.route('/api/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    try:
        # Create a session
        session = Session()

        # Find the item by ID
        item = session.query(Item).get(item_id)
        if not item:
            return jsonify({'message': 'Item not found!'}), 404
        
        # Delete the item
        session.delete(item)
        session.commit()

        # Close the session
        session.close()

        return jsonify({'message': 'Item deleted successfully!'})
    
    except SQLAlchemyError as e:
        # Handle any database errors
        return jsonify({'status': 'error', 'message': str(e)}), 500

# Route to check the database connection
@app.route('/api')
def check_db_connection():
    try:
        # Test connection by executing a simple query
        with engine.connect() as connection:
            result = connection.execute(text('SELECT 1;'))
            for _ in result:
                pass  # Just to fetch the result
        return jsonify({'status': 'success', 'message': 'Database connection is healthy!'})
    except SQLAlchemyError as e:
        # Return error message if the connection fails
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
