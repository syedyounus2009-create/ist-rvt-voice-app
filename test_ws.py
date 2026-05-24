import asyncio
import websockets

async def test():
    try:
        url = "wss://ist-rvt-backend.onrender.com/ws/audio/test_room?user_id=123&source_lang=en&target_lang=ar"
        # For websockets < 11.0, it's extra_headers. For 11.0+ it's also extra_headers or just headers. Let's just try without headers first, or use a basic approach.
        print(f"Connecting to {url}...")
        async with websockets.connect(url) as ws:
            print("Connected successfully!")
            await ws.close()
    except Exception as e:
        print(f"Error: {e}")

asyncio.run(test())
