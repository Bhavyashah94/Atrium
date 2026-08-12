
```bash
curl -s -X GET "http://localhost:3001/info" | jq '{
  cpu: {
    cpu_brand: (.cpu.brand + " " + .cpu.model),
    cores: .cpu.cores,
    threads: .cpu.threads,
    freq: .cpu.frequency
  },
  ram: {
    total_capacity: (((.ram.size / 1024 / 1024 / 1024) * 100 | trunc) / 100),
    sticks: [
      .ram.layout[] | {
        ram_brand: .brand,
        type: .type,
        frequency: .frequency
      }
    ]
  },
  storage: [
    .storage[] | .size as $disk_size | .disks[] | {
      storage_brand: .brand,
      device: .device,
      type: .type,
      capacity: (($disk_size / 1024 / 1024 / 1024 * 100 | trunc) / 100)
    }
  ],
  network: {
    type: .network.type,
    down_MBps: (((.network.speedDown / 1024 / 1024) * 100 | trunc) / 100),
    up_MBps: (((.network.speedUp / 1024 / 1024) * 100 | trunc) / 100)
  },
  gpu: .gpu.layout
}'
```

Response Payload: 
```bash
{
  "cpu": {
    "cpu_brand": "Intel Core™ i3-6100T",
    "cores": 2,
    "threads": 4,
    "freq": 3.2
  },
  "ram": {
    "total_capacity": 7.63,
    "sticks": [
      {
        "ram_brand": "Unknown - [0x0000]",
        "type": "DDR4",
        "frequency": 2133
      }
    ]
  },
  "storage": [
    {
      "storage_brand": "ATA",
      "device": "sda",
      "type": "SSD",
      "capacity": 476.93
    },
    {
      "storage_brand": "WDC WD10",
      "device": "sdd",
      "type": "HD",
      "capacity": 931.51
    }
  ],
  "network": {
    "type": "Wired",
    "down_MBps": 141.1,
    "up_MBps": 113.41
  },
  "gpu": []
}
```


2. `curl http://localhost:3001/load/cpu | jq`

Response Payload: 
```bash
[
  {
    "load": 24.46808510638298,
    "temp": 39,
    "core": 0
  },
  {
    "load": 28.865979381443296,
    "temp": 39,
    "core": 1
  },
  {
    "load": 18.367346938775512,
    "temp": 41,
    "core": 2
  },
  {
    "load": 39.175257731958766,
    "temp": 41,
    "core": 3
  }
]
```

3. `curl http://localhost:3001/load/ram | jq '{load: (((.load / 1024 / 1024 / 1024) * 100) | trunc / 100)}'`

Response Payload: 
```bash
{
  "load": 4.96
}
```

4. `curl -s http://100.86.78.83:3005/load/storage | jq 'map(if . < 0 then . else ((. / 1073741824 * 100 | trunc) / 100) end)'`

Response Payload: 
```bash
[
  -1,
  537.38
]
```

5. `curl -s http://100.86.78.83:3005/load/network | jq '{
  up_MBps: (((.up / 1024 / 1024) * 100 | trunc) / 100),
  down_MBps: (((.down / 1024 / 1024) * 100 | trunc) / 100)
}'`

Response Payload:
```bash
{
  "up_MBps": 0.06,
  "down_MBps": 0.02
}
```

5. `curl -s http://localhost:3001/info | jq '{gpu: {gpus: (.gpu.layout | map({name: "\(.brand) \(.model)", memory}))}}'`

Response Payload: 
```bash
{
  "gpu": {
    "gpus": [
      {
        "name": "NVIDIA GeForce GTX 1650",
        "memory": 4096
      },
      {
        "name": "Advanced Micro Devices, Inc. [AMD/ATI] Cezanne",
        "memory": 512
      }
    ]
  }
}```

6. `curl -s http://localhost:3001/load/storage | jq '.[] / 1024 / 1024 / 1024'`

Response Payload:
```bash
461.6812934875488
```
