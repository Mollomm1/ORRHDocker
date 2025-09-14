# ORRHDocker

A Docker-based solution for deploying low-privilege, headless OnlyRetroRobloxHere servers quickly and easily.

> if you are looking for a similar solution for Novetus use [NovetusDocker](https://github.com/Mollomm1/NovetusDocker).

---

## 🚧 Build Instructions

1. **Get a linux server/desktop or WSL**

2. **Install docker and docker buildx**

3. **Build the Docker Image**
   Use Docker Buildx to create the image:

   ```bash
   docker build -t orrh .
   ```

---

## ▶️ Run Instructions

Start a OnlyRetroRobloxHere server using Docker:

```bash
docker run -d \
  --name=orrh \
  --restart always \
  -p 53640:53640/udp \
  -p 127.0.0.1:3000:3000 `# Optional: Track connected players on the server, it is heavely recommended to put this behind a reverse proxy.` \
  -e CLIENT=2013L `# Optional: Select the client version (default: 2013L)` \
  -v ./mymap.rbxl:/config/OnlyRetroRobloxHere/maps/default.rbxl `# Optional: Mount a custom map` \
  -v ./Plugins:/config/Plugins `# Optional: Add custom plugins` \
  orrh
```

---

## ✅ Supported Client Versions

| Version Code | Description | Notes |
| --- | --- | --- |
| 2013L | **Default** | ✅ Works |
| 2013M-2008M | Supported | ✅ Works |
| 2008E-2007M | Supported | 🟧 Works, but insecure. |
| 2007E-FakeFeb | Supported | 🟧 Works, but insecure. Can't track players. |
| 2007E | Supported | 🟧 Works, but insecure. Can't track players. |

## 👨‍💻 Custom Plugins

ORRHDocker supports custom server plugins, which follow a structure very similar to Novetus addons.
To use them, simply mount any folder containing your `.lua` plugin files to `/config/Plugins`.

For reference, you can check out the included [example.lua](https://github.com/Mollomm1/ORRHDocker/blob/main/scripts/orrh_plugins/plugins/example.lua).