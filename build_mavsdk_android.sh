git clone https://github.com/openssl/openssl.git --recursive &&
cp openssl_android.sh ./openssl/. && cd openssl && sh ./openssl_android.sh &&
cd .. && git clone https://github.com/mavlink/MAVSDK.git --recursive &&
cp ./third_party_CMakeLists.txt ./MAVSDK/third_party/CMakeLists.txt &&
cp android.sh ./MAVSDK/. && cd MAVSDK && sh ./android.sh 
