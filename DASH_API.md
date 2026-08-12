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
