const API_URL = "http://127.0.0.1:8000";

async function createFarmer() {
    const name = document.getElementById("farmerName").value;
    const location = document.getElementById("farmerLocation").value;

    const response = await fetch(`${API_URL}/farmers/`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, location })
    });

    const data = await response.json();
    alert("Farmer Registered with ID: " + data.id);
}

async function createListing() {
    const title = document.getElementById("title").value;
    const description = document.getElementById("description").value;
    const category = document.getElementById("category").value;
    const estimated_value = parseFloat(document.getElementById("value").value);
    const owner_id = parseInt(document.getElementById("ownerId").value);

    const response = await fetch(`${API_URL}/listings/`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title, description, category, estimated_value, owner_id })
    });

    const data = await response.json();
    alert("Listing Created with ID: " + data.id);
}

async function loadListings() {
    const response = await fetch(`${API_URL}/listings/`);
    const listings = await response.json();

    const list = document.getElementById("listingList");
    list.innerHTML = "";

    listings.forEach(item => {
        const li = document.createElement("li");
        li.innerText = `${item.title} - ₹${item.estimated_value} (Owner ID: ${item.owner_id})`;
        list.appendChild(li);
    });
}