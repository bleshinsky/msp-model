# MSP Neo4j Docker Setup

Quick Neo4j setup for MSP using Docker.

## Quick Start

```bash
# Start Neo4j
docker-compose up -d

# Wait for Neo4j to be ready (about 30 seconds)
docker-compose logs -f neo4j

# Access Neo4j Browser
# URL: http://localhost:7474
# Username: neo4j
# Password: msp-password
```

## First Time Setup

1. Start Neo4j:
   ```bash
   docker-compose up -d
   ```

2. Open Neo4j Browser at http://localhost:7474

3. Login with:
   - Username: `neo4j`
   - Password: `msp-password`

4. Run MSP schema setup:
   ```powershell
   cd ..
   .\scripts\integrations\neo4j\setup-neo4j.ps1 -CreateSchema
   ```

5. Copy the generated queries to Neo4j Browser and execute

## Management Commands

### View logs
```bash
docker-compose logs -f neo4j
```

### Stop Neo4j
```bash
docker-compose down
```

### Stop and remove all data
```bash
docker-compose down -v
```

### Restart Neo4j
```bash
docker-compose restart neo4j
```

## Configuration

The docker-compose.yml includes:

- **Memory Settings**: Optimized for development (512MB heap, 2GB max)
- **APOC Plugin**: Advanced procedures for data import/export
- **Persistent Volumes**: Data survives container restarts
- **Health Checks**: Ensures Neo4j is ready before use

## Customization

### Change Password

Edit `docker-compose.yml`:
```yaml
environment:
  - NEO4J_AUTH=neo4j/your-new-password
```

### Adjust Memory

For larger projects, increase memory:
```yaml
environment:
  - NEO4J_server_memory_heap_max__size=4G
  - NEO4J_server_memory_pagecache__size=1G
```

### Add More Plugins

Add plugins to the plugins list:
```yaml
environment:
  - NEO4JLABS_PLUGINS=["apoc", "graph-data-science"]
```

## Troubleshooting

### Container won't start
Check if ports are already in use:
```bash
netstat -an | findstr "7474 7687"
```

### Can't connect to Neo4j
Ensure the container is healthy:
```bash
docker-compose ps
```

### Reset everything
```bash
docker-compose down -v
docker-compose up -d
```

## Integration with MSP

Once Neo4j is running:

1. Update your MSP config:
   ```json
   {
     "neo4j": {
       "uri": "bolt://localhost:7687",
       "username": "neo4j",
       "password": "msp-password"
     }
   }
   ```

2. Test the connection:
   ```powershell
   .\scripts\integrations\neo4j\setup-neo4j.ps1 -TestConnection
   ```

3. Start using MSP:
   ```powershell
   .\msp.ps1 start
   ```

## Production Considerations

This setup is for development. For production:

- Use Neo4j Enterprise Edition
- Configure proper authentication
- Set up SSL/TLS
- Implement backup strategies
- Monitor performance
- Use dedicated hosting

