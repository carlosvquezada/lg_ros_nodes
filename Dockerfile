FROM ubuntu:xenial

# prevent interactive prompts during build
ENV DEBIAN_FRONTEND noninteractive

# project settings
ENV PROJECT_ROOT $HOME/src/lg_ros_nodes
ENV ROS_DISTRO kinetic
ENV OS_VERSION xenial

# Env for nvidia-docker2/nvidia container runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all

# entrypoint for ROS setup.bash
COPY scripts/docker_entrypoint.sh /ros_entrypoint.sh
RUN chmod 0755 /ros_entrypoint.sh
ENTRYPOINT ["/ros_entrypoint.sh"]

# install system dependencies and tools not tracked in rosdep
RUN \
  apt-get update -y && apt-get install -y ca-certificates wget && \
  echo "deb http://packages.ros.org/ros/ubuntu $OS_VERSION main" > /etc/apt/sources.list.d/ros-latest.list && \
  echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
  echo "deb http://dl.google.com/linux/earth/deb/ stable main" > /etc/apt/sources.list.d/google-earth.list &&\
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116 && \
  wget --no-check-certificate -q -O /tmp/key.pub https://dl-ssl.google.com/linux/linux_signing_key.pub && apt-key add /tmp/key.pub && rm /tmp/key.pub && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    automake autoconf libtool \
    g++ pep8 cppcheck closure-linter \
    python-pytest wget \
    python-gst-1.0 \
    python-setuptools \
    git sudo \
    curl tmux git \
    xvfb x11-apps \
    x-window-system binutils \
    pulseaudio \
    mesa-utils mesa-utils-extra \
    module-init-tools gdebi-core \
    lsb-core tar libfreeimage3 \
    ros-$ROS_DISTRO-rosapi libudev-dev \
    ros-$ROS_DISTRO-ros-base ros-$ROS_DISTRO-rosbridge-server ros-$ROS_DISTRO-web-video-server \
    ros-$ROS_DISTRO-spacenav-node spacenavd \
    google-chrome-stable google-chrome-beta google-chrome-unstable \
    awesome xdg-utils \
 && rm -rf /var/lib/apt/lists/* \
 && easy_install pip \
 && pip install -U --no-cache-dir pip \
 && pip install --no-cache-dir python-coveralls

# Install GE
ENV GOOGLE_EARTH_VERSION ec_7.3.0.3832_64
ENV EARTH_PKG_URL https://roscoe-assets.galaxy.endpoint.com:443/google-earth/google-earth-stable_${GOOGLE_EARTH_VERSION}.deb
RUN mkdir -p /tmp/GE \
 && cd /tmp/GE \
 && wget $EARTH_PKG_URL \
 && dpkg -i $( basename $EARTH_PKG_URL ) \
 && rm $( basename $EARTH_PKG_URL ) \
 && if [ -f "/opt/google/earth/free/libfreebl3.so" ]; then sed -i "s_/etc/passwd_/not/anywhr_g" "/opt/google/earth/free/libfreebl3.so"; fi

# add non-root user for tests and production
ENV RUN_USER galadmin
ENV HOME /home/${RUN_USER}
RUN \
      useradd -ms /bin/bash $RUN_USER && \
      usermod -a -G sudo,plugdev,audio,video $RUN_USER && \
      mkdir -p $HOME/src ;\
      echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /root/.bash_profile ;\
      echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> $HOME/.bash_profile ;\
      mv /bin/sh /bin/sh.bak && ln -s /bin/bash /bin/sh && \
      mkdir -p $PROJECT_ROOT/src

# clone appctl
ARG APPCTL_TAG=1.2.1
RUN git clone --branch ${APPCTL_TAG} https://github.com/EndPointCorp/appctl.git $PROJECT_ROOT/appctl

# pre-install dependencies for each package
COPY interactivespaces_msgs/package.xml ${PROJECT_ROOT}/interactivespaces_msgs/package.xml
COPY lg_activity/package.xml ${PROJECT_ROOT}/lg_activity/package.xml
COPY lg_attract_loop/package.xml ${PROJECT_ROOT}/lg_attract_loop/package.xml
COPY lg_builder/package.xml ${PROJECT_ROOT}/lg_builder/package.xml
COPY lg_common/package.xml ${PROJECT_ROOT}/lg_common/package.xml
COPY lg_earth/package.xml ${PROJECT_ROOT}/lg_earth/package.xml
COPY lg_json_config/package.xml ${PROJECT_ROOT}/lg_json_config/package.xml
COPY lg_keyboard/package.xml ${PROJECT_ROOT}/lg_keyboard/package.xml
COPY lg_media/package.xml ${PROJECT_ROOT}/lg_media/package.xml
COPY lg_mirror/package.xml ${PROJECT_ROOT}/lg_mirror/package.xml
COPY lg_nav_to_device/package.xml ${PROJECT_ROOT}/lg_nav_to_device/package.xml
COPY lg_offliner/package.xml ${PROJECT_ROOT}/lg_offliner/package.xml
COPY lg_panovideo/package.xml ${PROJECT_ROOT}/lg_panovideo/package.xml
COPY lg_pointer/package.xml ${PROJECT_ROOT}/lg_pointer/package.xml
COPY lg_proximity/package.xml ${PROJECT_ROOT}/lg_proximity/package.xml
COPY lg_replay/package.xml ${PROJECT_ROOT}/lg_replay/package.xml
COPY lg_rfreceiver/package.xml ${PROJECT_ROOT}/lg_rfreceiver/package.xml
COPY lg_screenshot/package.xml ${PROJECT_ROOT}/lg_screenshot/package.xml
COPY lg_spacenav_globe/package.xml ${PROJECT_ROOT}/lg_spacenav_globe/package.xml
COPY lg_stats/package.xml ${PROJECT_ROOT}/lg_stats/package.xml
COPY lg_sv/package.xml ${PROJECT_ROOT}/lg_sv/package.xml
COPY lg_twister/package.xml ${PROJECT_ROOT}/lg_twister/package.xml
COPY lg_volume_control/package.xml ${PROJECT_ROOT}/lg_volume_control/package.xml
COPY lg_wireless_devices/package.xml ${PROJECT_ROOT}/lg_wireless_devices/package.xml
COPY liquidgalaxy/package.xml ${PROJECT_ROOT}/liquidgalaxy/package.xml
COPY rfid_scanner/package.xml ${PROJECT_ROOT}/rfid_scanner/package.xml
COPY rfreceiver/package.xml ${PROJECT_ROOT}/rfreceiver/package.xml
COPY rosbridge_library/package.xml ${PROJECT_ROOT}/rosbridge_library/package.xml
COPY rosbridge_server/package.xml ${PROJECT_ROOT}/rosbridge_server/package.xml
COPY spacenav_remote/package.xml ${PROJECT_ROOT}/spacenav_remote/package.xml
COPY spacenav_wrapper/package.xml ${PROJECT_ROOT}/spacenav_wrapper/package.xml
COPY state_proxy/package.xml ${PROJECT_ROOT}/state_proxy/package.xml
COPY wiimote/package.xml ${PROJECT_ROOT}/wiimote/package.xml
RUN \
    source /opt/ros/$ROS_DISTRO/setup.bash && \
    apt-get update && \
    rosdep init && \
    rosdep update && \
    rosdep install \
        --from-paths $PROJECT_ROOT \
        --ignore-src \
        --rosdistro $ROS_DISTRO \
        -y && \
    rm -rf /var/lib/apt/lists/*

# install the full package contents
COPY ./ ${PROJECT_ROOT}
RUN \
    cd ${PROJECT_ROOT} && \
    source /opt/ros/$ROS_DISTRO/setup.bash && \
    /ros_entrypoint.sh ./scripts/init_workspace -a $PROJECT_ROOT/appctl && \
    cd ${PROJECT_ROOT}/catkin/ && \
    catkin_make && \
    catkin_make -DCMAKE_INSTALL_PREFIX=/opt/ros/$ROS_DISTRO install && \
    source $PROJECT_ROOT/catkin/devel/setup.bash && \
    chown -R ${RUN_USER}:${RUN_USER} ${HOME}


# Massage libglvnd so opengl plays nicely with nvidia-docker2
ARG LIBGLVND_VERSION='v1.1.0'

RUN mkdir /opt/libglvnd && \
    cd /opt/libglvnd && \
    git clone --branch="${LIBGLVND_VERSION}" https://github.com/NVIDIA/libglvnd.git . && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/x86_64-linux-gnu && \
    make -j"$(nproc)" install-strip && \
    find /usr/local/lib/x86_64-linux-gnu -type f -name 'lib*.la' -delete

RUN echo '/usr/local/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf

ENV LD_LIBRARY_PATH /usr/local/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}


USER $RUN_USER

# by default let's run tests
#CMD cd ${PROJECT_ROOT}/catkin && \
#    . devel/setup.sh && \
#    cd ${PROJECT_ROOT} && \
#    ./scripts/docker_xvfb_add.sh && \
#    ./scripts/test_runner.py
