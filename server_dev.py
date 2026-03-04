"""
Alternative server startup using Flask's development server
"""

import os
from app.main import app
from app.config import settings

if __name__ == "__main__":
    port = settings.PORT
    
    print("""
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🕉️  Ganesh Donations API Server (Flask Dev Server)     ║
║                                                           ║
║   Status: ✅ RUNNING                                      ║
║   Port: {}                                             ║
║   Environment: development                                ║
║                                                           ║
║   Health: http://localhost:{}/health                  ║
║   API Docs: http://localhost:{}                       ║
║                                                           ║
║   गणपती बाप्पा मोरया! 🙏                                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
    """.format(port, port, port))
    
    app.run(
        host="0.0.0.0",
        port=port,
        debug=True
    )
