#!/bin/bash
sudo ufw allow 6443/tcp && \
sudo ufw allow 10250/tcp && \
sudo ufw allow 30000:32767/tcp && \
sudo ufw allow 30000:32767/udp && \
sudo ufw allow 2379:2380/tcp && \
sudo ufw allow 51820/udp && \
sudo ufw enable && \
sudo ufw reload
