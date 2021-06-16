# Check connection on IP
Test-Connection 8.8.8.8

Source        Destination     IPV4Address      Bytes    Time(ms)
------        -----------     -----------      -------  ----
lab01         8.8.8.8         8.8.8.8          32       12
lab01         8.8.8.8         8.8.8.8          32       13

# Check connection on DNS Name
Test-Connection bing.com