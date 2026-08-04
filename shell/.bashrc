# ~/.bashrc
#
# Enable color support for ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Colored prompt
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
alias asd="source ~/.bashrc"
export EDITOR=nano

# ROS Setup
source /opt/ros/noetic/setup.bash
source ~/ros1_ws/devel/setup.bash
export DISABLE_ROS1_EOL_WARNINGS=1

# PX4 Setup
export PX4_HOME=/home/aly/PX4-Autopilot

source /home/aly/PX4-Autopilot/Tools/simulation/gazebo-classic/setup_gazebo.bash /home/aly/PX4-Autopilot /home/aly/PX4-Autopilot/build/px4_sitl_default

# Gazebo Paths
export GAZEBO_MODEL_PATH=/home/aly/Storage/college/4thProj/Gazebo-Models:/home/aly/.gazebo/models:/home/aly/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic/models
export GAZEBO_RESOURCE_PATH=/home/aly/Storage/college/4thProj/Gazebo-Models:/usr/share/gazebo-11
export GAZEBO_PLUGIN_PATH=$GAZEBO_PLUGIN_PATH:/home/aly/PX4-Autopilot/build/px4_sitl_default/build_gazebo-classic
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/aly/PX4-Autopilot/build/px4_sitl_default/build_gazebo-classic

# ROS Package Path
export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:/home/aly/PX4-Autopilot:/home/aly/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic
export GAZEBO_MODEL_DATABASE_URI=""

# Qt Platform
#export QT_QPA_PLATFORM=xcb

alias cam="setsid rosrun tf static_transform_publisher 0 0 0 0 0 0 BB/base_link camera_link 100 && rviz"
clear
export PATH=/usr/bin:$PATH
export PATH=/usr/bin:$PATH
#export PATH=$PATH:/opt/xtensa-esp-elf/bin/
alias sim="roslaunch px4 mavros_posix_sitl.launch vehicle:=BB world:=/home/aly/Storage/college/4thProj/Gazebo-Models/CHS-Room/CHS-Room.world"

export STM32_PRG_PATH=/home/aly/cuh/stmEnv/STM32CubeProgrammer/binsource

# Source PX4 Gazebo setup
source /home/aly/PX4-Autopilot/Tools/simulation/gazebo-classic/setup_gazebo.bash /home/aly/PX4-Autopilot /home/aly/PX4-Autopilot/build/px4_sitl_default
# Add PX4 to ROS package path
export ROS_PACKAGE_PATH=/home/aly/PX4-Autopilot:/home/aly/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic:$ROS_PACKAGE_PATH

# Gazebo paths
export GAZEBO_MODEL_PATH=/home/aly/Storage/college/4thProj/Gazebo-Models:/home/aly/.gazebo/models:/home/aly/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic/models
export GAZEBO_RESOURCE_PATH=/home/aly/Storage/college/4thProj/Gazebo-Models:/usr/share/gazebo-11
export GAZEBO_PLUGIN_PATH=$GAZEBO_PLUGIN_PATH:/home/aly/PX4-Autopilot/build/px4_sitl_default/build_gazebo-classic
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/aly/PX4-Autopilot/build/px4_sitl_default/build_gazebo-classic
clear
#export DRI_PRIME=pci-0000:05:00.0
#export MESA_GL_VERSION_OVERRIDE=3.3
export ROS_PACKAGE_PATH=/home/aly/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic:$ROS_PACKAGE_PATH
export ROS_PACKAGE_PATH=/home/aly/PX4-Autopilot:$ROS_PACKAGE_PATH
alias sim="roslaunch px4 posix_sitl.launch vehicle:=hexa world:=/home/aly/.gazebo/worlds/rice_field.world"
# Set DISPLAY based on whether X11 is running
if pgrep -x "Xorg" >/dev/null || pgrep -x "X" >/dev/null; then
    export DISPLAY=:1
else
    export QT_QPA_PLATFORM=xcb
    export DISPLAY=:0
fi
export GAZEBO_PLUGIN_PATH=$GAZEBO_PLUGIN_PATH:$HOME/catkin_ws/devel/lib
alias mission="cd ~/catkin_ws && catkin_make && source devel/setup.bash && roslaunch drone_mission mission.launch"
alias sim="roslaunch px4 posix_sitl.launch vehicle:=hexa world:=/home/aly/.gazebo/worlds/rice_field.world"
alias  fix='LIBGL_ALWAYS_SOFTWARE=1 gazebo'
#export PATH=$PATH:/opt/xtensa-esp-elf/bin/:/home/aly/cuh/esp/xtensa-esp32s3-elf/bin:/home/aly/cuh/.espressif/tools/xtensa-esp32-elf/esp-2021r2-patch5-8.4.0/xtensa-esp32-elf/bin
alias g-old="g++-11 -std=c++23 flightsim.cpp -o FlightSimulator -I/usr/include/eigen3  -Wl,-Bstatic -lxlsxio_read -Wl,-Bdynamic -lexpat -lminizip -lz -lm -lserial"
alias staticFLSIM="g++-9 -std=c++17 flightsim.cpp -o FlightSimulator \
  -I/usr/include/eigen3 \
  -Wl,-Bstatic -lxlsxio_read -L/usr/local/lib -lserial -Wl,-Bdynamic \
  -lexpat -lminizip -lz -lm"
source /opt/ros/humble/setup.bash
