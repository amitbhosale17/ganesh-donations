"""Test if the app can be imported and run"""
import sys
try:
    print("Importing app...")
    from app.main import app
    print("✅ App imported successfully")
    
    print("\nTesting health endpoint...")
    with app.test_client() as client:
        response = client.get('/health')
        print(f"Status: {response.status_code}")
        print(f"Response: {response.get_json()}")
        
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
