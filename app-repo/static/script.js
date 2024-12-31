console.log('Static content served successfully!');

const backendServiceHost = "{{ .Release.Name }}-backend";
const backendPort = "{{ .Values.backend.service.port }}";

document.getElementById('createItemForm').addEventListener('submit', async (event) => {
    event.preventDefault();
    const name = document.getElementById('name').value;
    const description = document.getElementById('description').value;

    try {
        const response = await fetch('http://${backendServiceHost}:${backendPort}/api/items', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, description }),
        });

        const data = await response.json();
        alert(data.message || 'Error occurred!');
        loadItems();
    } catch (error) {
        console.error('Error during fetch:', error);
        alert('Error occurred!');
    }
});

async function loadItems() {
    try {
        const response = await fetch('http://${backendServiceHost}:${backendPort}/api/items');
        const items = await response.json();

        const itemsList = document.getElementById('itemsList');
        itemsList.innerHTML = '';
        items.forEach(item => {
            const listItem = document.createElement('li');
            listItem.innerHTML = `
                ${item.name}: ${item.description || 'No description'}
                <button onclick="editItem(${item.id}, '${item.name}', '${item.description}')">Edit</button>
                <button onclick="deleteItem(${item.id})">Delete</button>
            `;
            itemsList.appendChild(listItem);
        });
    } catch (error) {
        console.error('Error loading items:', error);
        alert('Error occurred while loading items!');
    }
}

function editItem(id, name, description) {
    document.getElementById('editItemForm').style.display = 'block';
    document.getElementById('editItemId').value = id;
    document.getElementById('editName').value = name;
    document.getElementById('editDescription').value = description;
}

document.getElementById('editItemForm').addEventListener('submit', async (event) => {
    event.preventDefault();
    const id = document.getElementById('editItemId').value;
    const name = document.getElementById('editName').value;
    const description = document.getElementById('editDescription').value;

    try {
        const response = await fetch(`http://${backendServiceHost}:${backendPort}/api/items/${id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, description }),
        });

        const data = await response.json();
        alert(data.message || 'Error occurred!');
        document.getElementById('editItemForm').style.display = 'none';
        loadItems();
    } catch (error) {
        console.error('Error during fetch:', error);
        alert('Error occurred!');
    }
});

async function deleteItem(id) {
    if (!confirm('Are you sure you want to delete this item?')) return;

    try {
        const response = await fetch(`http://${backendServiceHost}:${backendPort}/api/items/${id}`, {
            method: 'DELETE',
        });

        const data = await response.json();
        alert(data.message || 'Error occurred!');
        loadItems();
    } catch (error) {
        console.error('Error during fetch:', error);
        alert('Error occurred!');
    }
}
