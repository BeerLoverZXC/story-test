FROM ubuntu:latest

ENV DAEMON_NAME=story \
DAEMON_HOME=/app/.story/story \
DAEMON_ALLOW_DOWNLOAD_BINARIES=false \
DAEMON_RESTART_AFTER_UPGRADE=true \
MONIKER="Stake Shark" \
STORY_PORT="52" \
GO_VER="1.22.3" \
PATH="/usr/local/go/bin:/app/go/bin:${PATH}" \
SEEDS="434af9dae402ab9f1c8a8fc15eae2d68b5be3387@story-testnet-seed.itrocket.net:29656" \
PEERS="c2a6cc9b3fa468624b2683b54790eb339db45cbf@story-testnet-peer.itrocket.net:26656,02e9fac0fab468724db00e5e3328b2cbca258fdc@95.217.193.182:26656,5c001659b68370e7198e9c6c72bfc4c3c15dba41@211.218.55.32:50656,e1245ea24138ff16ca144962f72146d6afcbfe15@221.148.45.118:26656,34400e930af9ff63a0c2c2d1b036a8763e7c92e1@158.220.126.24:52656,959ef7ebaaacd08de053e738707d3a2940f846a4@148.72.138.5:26656,5531e438ecd2e0b0d2700e68b2ba8066eb02d2d7@185.133.251.245:656,29d7d1d203ccf8c9afe593eab7bee485f1e6bbfa@37.252.186.234:26656,bf975933a1169221e3bd04164a7ba9abc5d164c8@3.16.175.31:26656,f0e8398215663070d0d65ea6478f61688228d9d9@3.146.164.199:26656,04e5734295da362f09a61dd0a9999449448a0e5c@52.14.39.177:26656,046909534c2849ff8dccc15ee43ee63d2c60b21c@54.190.123.194:26656,9e2fabda41e3c3317c25f5ef6c604c1d78370aba@50.112.252.101:26656,b954afe1c26b82cf0628642c82ffee13e108387d@165.154.225.142:26656,bd58bf29180f476bd250af22d6026559d7eff289@146.59.118.198:26656,0ae60326fa7f01500a94dd7f0d2571fbba46cd10@167.235.39.5:17656,8b241f57d1375205aa4a17d038f9825a516ccbc5@88.99.252.213:36656,466291d2485a4a4adbafdc913ef23b1286d1b110@144.76.92.22:26656,2fe77b469daa58e26bb96e0ea6208856fa59e548@192.64.87.158:26656,7ecb96bb4778b3f979be7c8e720cc9ee739ac770@104.198.43.15:26656,39ef8bba040a71d6914359ba0f6f8490f7716c35@45.61.156.53:26656,73aafbaefe85e64a3eb0c6e23b3935bc308d77db@142.132.135.125:20656,2e65e5de93cb19ee35b1e82af7f874043a1f5d83@185.133.251.252:656,8ff41ff3354241f608ba15ccd224ff6fb7393dd7@135.181.60.149:26656,c5c214377b438742523749bb43a2176ec9ec983c@176.9.54.69:26656,fa294c4091379f84d0fc4a27e6163c956fc08e73@65.108.103.184:26656,75ac7b193e93e928d6c83c273397517cb60603c0@3.142.16.95:26656,356847ca14f13b9b38d13bfaf7751ae74cc2919b@65.21.210.147:26656,443896c7ec4c695234467da5e503c78fcd75c18e@80.241.215.215:26656,e8317a671abf0af33eb712045f368ac5f335d690@2.56.246.4:18656,176325c2f78f146fb09bebc6c287f430654b448c@84.247.174.15:656"

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl git wget htop tmux build-essential jq make lz4 gcc unzip && \
    rm -rf /var/lib/apt/lists/*

RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" -q && \
    tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
    rm "go$GO_VER.linux-amd64.tar.gz" && \
    mkdir -p /app/go/bin /app/.story/story /app/.story/geth

RUN wget -O /app/go/bin/geth https://github.com/piplabs/story-geth/releases/download/v0.11.0/geth-linux-amd64 && \
    chmod +x /app/go/bin/geth

RUN mkdir -p /app/.story/story/cosmovisor/genesis/bin && \
mkdir -p /app/.story/story/cosmovisor/upgrades

RUN chmod +x /root/.gaia/cosmovisor/genesis/bin/gaiad

RUN git clone https://github.com/piplabs/story /app/story && \
    cd /app/story && \
    git checkout v0.13.2 && \
    go build -o story ./client && \
    mv /app/story/story /app/.story/story/cosmovisor/genesis/bin/

RUN wget "https://github.com/cosmos/cosmos-sdk/releases/download/v0.44.0/cosmovisor-linux-amd64" -q && \
    mv cosmovisor-linux-amd64 /usr/bin/cosmovisor && \
    chmod +x /usr/bin/cosmovisor

RUN story init --moniker "Stake Shark" --network odyssey --chain-id 1513 && \
    sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
           -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
           /app/.story/story/config/config.toml && \
    sed -i.bak -e "s%:1317%:${STORY_PORT}317%g; \
                   s%:8551%:${STORY_PORT}551%g" \
           /app/.story/story/config/story.toml && \
    sed -i.bak -e "s%:26658%:${STORY_PORT}658%g; \
                   s%:26657%:${STORY_PORT}657%g; \
                   s%:26656%:${STORY_PORT}656%g; \
                   s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${STORY_PORT}656\"%" \
           /app/.story/story/config/config.toml && \
    sed -i -e "s/prometheus = false/prometheus = true/" /app/.story/story/config/config.toml && \
    sed -i -e "s/^indexer *=.*/indexer = \"null\"/" /app/.story/story/config/config.toml

RUN wget -O /app/.story/story/config/genesis.json https://server-3.itrocket.net/testnet/story/genesis.json && \
    wget -O /app/.story/story/config/addrbook.json https://server-3.itrocket.net/testnet/story/addrbook.json

ENTRYPOINT ["cosmovisor", "start"]
