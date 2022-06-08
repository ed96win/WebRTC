name=edwin
## ================================create docker container with random AVAILABLE ports================================== ##
obsport=1935
webrtcport=3333
originport=9000
tcprelayport=3478
mpegtsport=4000
srtport=9999
iceport1=10000
while
obsport=$(($obsport+1))
webrtcport=$(($webrtcport+1))
securewebrtcport=$(($webrtcport+1))
originport=$(($originport+1))
iceport1=$(($iceport1+1))
iceport2=$(($iceport1+10))
tcprelayport=$(($tcprelayport+1))
mpegtsport=$(($mpegtsport+1))
srtport=$(($srtport-1))
netstat -atun | grep -q "$obsport"
netstat -atun | grep -q "$webrtcport"
netstat -atun | grep -q "$securewebrtcport"
netstat -atun | grep -q "$originport"
netstat -atun | grep -q "$iceport1"
netstat -atun | grep -q "$iceport2"
do
continue
done

#create docker container with specified ports
docker run -d --name edwin -p $obsport:1935 -p $webrtcport:3333 -p $securewebrtcport:3334 -p $originport:9000 -p $tcprelayport:3478 -p $mpegtsport:4000/udp -p $srtport:9999/udp -p $iceport1-$iceport2:10000-10010/udp airensoft/ovenmediaengine:dev

## ================================ run modifications on container ================================================================= ##
#get container id matching the name
containerid=$(sudo docker ps -aqf "name=edwin")

echo id is $containerid

#rename app name to app6969 where 6969 is a random number generated
id=$(shuf -i 1-9999 -n 1)
docker exec $containerid sed -i 's/<Name>app<\/Name>/<Name>app'$id'<\/Name>/g' /opt/ovenmediaengine/bin/origin_conf/Server.xml

echo appname edited

#copy wildcard ssl files to docker containers
docker cp /root/ssl/cert.crt $containerid:/opt/ovenmediaengine/bin/origin_conf/cert.crt
docker cp /root/ssl/priv8.key $containerid:/opt/ovenmediaengine/bin/origin_conf/priv8.key
docker cp /root/ssl/chain.crt $containerid:/opt/ovenmediaengine/bin/origin_conf/chain.crt

echo ssl files placed

#specify certificate in config
docker exec $containerid sed -i 's|path/to/file.crt|/opt/ovenmediaengine/bin/origin_conf/cert.crt|g' /opt/ovenmediaengine/bin/origin_conf/Server.xml
docker exec $containerid sed -i 's|path/to/file.key|/opt/ovenmediaengine/bin/origin_conf/priv8.key|g' /opt/ovenmediaengine/bin/origin_conf/Server.xml
docker exec $containerid sed -i 's|path/to/file.crt|/opt/ovenmediaengine/bin/origin_conf/chain.crt|g' /opt/ovenmediaengine/bin/origin_conf/Server.xml

echo certificate specified

#enable securewebrtc
docker exec $containerid sed -i '57s|<!-- <TLSPort>3334</TLSPort> -->|<TLSPort>3334</TLSPort>|g' /opt/ovenmediaengine/bin/origin_conf/Server.xml
docker exec $containerid sed -i '91s|<!-- <TLSPort>3334</TLSPort> -->|<TLSPort>3334</TLSPort>|g' /opt/ovenmediaengine/bin/origin_conf/Server.xml
docker exec $containerid sed -i '142s|<!--||g' /opt/ovenmediaengine/bin/origin_conf/Server.xml
docker exec $containerid sed -i '148s|-->||g' /opt/ovenmediaengine/bin/origin_conf/Server.xml

echo tls port enabled

#create an image with the container

docker commit $containerid edwin
docker stop edwin && docker rm edwin

docker run -d --name edwin -p $obsport:1935 -p $webrtcport:3333 -p $securewebrtcport:3334 -p $originport:9000 -p $tcprelayport:3478 -p $mpegtsport:4000/udp -p $srtport:9999/udp -p $iceport1-$iceport2:10000-10010/udp edwin

echo app$id