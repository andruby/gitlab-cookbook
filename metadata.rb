name             "gitlab"
maintainer       "Andrew Fecheyr"
maintainer_email "andrew@bedesign.be"
license          "MIT"
description      "Installs/Configures gitlab"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.2.1"

%w{git mysql database redisio build-essential python readline perl xml zlib apt nginx}.each do |cookbook|
  depends(cookbook)
end

supports "ubuntu"
supports "centos"
supports "amazon"