import functions_framework
from google.cloud import firestore
from datetime import datetime, timedelta
import pytz

# Initialize Firestore
db = firestore.Client()

@functions_framework.cloud_event
def revoke_old_tickets(cloud_event):
    """This function runs on a schedule to remove expired tickets."""
    print("🕓 Revoking expired tickets...")

    # Time logic
    now = datetime.now(pytz.UTC)
    cutoff = now - timedelta(days=1)

    # Fetch tickets older than 1 day
    tickets_ref = db.collection('tickets')
    old_tickets = tickets_ref.where('timestamp', '<', cutoff).stream()

    batch = db.batch()
    revoked_count = 0

    for doc in old_tickets:
        data = doc.to_dict()
        bus_id = data.get('busId')
        ticket_count = data.get('tickets', 1)

        print(f"🎫 Revoking ticket {doc.id} from bus {bus_id}")

        # Restore the seat to the bus
        bus_ref = db.collection('buses').document(bus_id)
        batch.update(bus_ref, {
            'availableSeats': firestore.Increment(ticket_count)
        })

        # Delete the old ticket or mark as expired
        batch.delete(doc.reference)
        revoked_count += 1

    # Commit all changes
    batch.commit()
    print(f"✅ {revoked_count} expired tickets revoked and seats restored.")
