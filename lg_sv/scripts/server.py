#!/usr/bin/env python

import rospy
from geometry_msgs.msg import Pose2D, Quaternion, Twist
from lg_common.helpers import get_first_asset_from_activity
from interactivespaces_msgs.msg import GenericMessage
from lg_common.msg import ApplicationState
from std_msgs.msg import String
from math import atan2, cos, sin, pi
from lg_sv import PanoViewerServer


# spacenav_node -> /spacenav/twist -> handle_spacenav_msg:
# 1. change pov based on rotational axes -> /<server_type>/pov
# 2. check for movement -> /<server_type>/panoid

# /<server_type>/location -> handle_location_msg:
# 1. query api, publish -> /<server_type>/panoid
# low priority

# /<server_type>/metadata -> handle_metadata_msg:
# 1. update self.metadata


DEFAULT_TILT_MIN = -80
DEFAULT_TILT_MAX = 80
DEFAULT_NAV_SENSITIVITY = 1.0
DEFAULT_NAV_INTERVAL = 0.02


def main():
    rospy.init_node('pano_viewer_server', anonymous=True)
    server_type = rospy.get_param('~server_type', 'streetview')
    location_pub = rospy.Publisher('/%s/location' % server_type,
                                   Pose2D, queue_size=1)
    panoid_pub = rospy.Publisher('/%s/panoid' % server_type,
                                 String, queue_size=1)
    pov_pub = rospy.Publisher('/%s/pov' % server_type,
                              Quaternion, queue_size=2)

    tilt_min = rospy.get_param('~tilt_min', DEFAULT_TILT_MIN)
    tilt_max = rospy.get_param('~tilt_max', DEFAULT_TILT_MAX)
    nav_sensitivity = rospy.get_param('~nav_sensitivity', DEFAULT_NAV_SENSITIVITY)
    space_nav_interval = rospy.get_param('~space_nav_interval', DEFAULT_NAV_INTERVAL)

    server = PanoViewerServer(location_pub, panoid_pub, pov_pub, tilt_min, tilt_max,
                              nav_sensitivity, space_nav_interval)

    rospy.Subscriber('/%s/location' % server_type, Pose2D,
                     server.handle_location_msg)
    rospy.Subscriber('/%s/metadata' % server_type, String,
                     server.handle_metadata_msg)
    rospy.Subscriber('/%s/panoid' % server_type, String,
                     server.handle_panoid_msg)
    rospy.Subscriber('/%s/pov' % server_type, Quaternion,
                     server.handle_pov_msg)
    rospy.Subscriber('/spacenav/twist', Twist,
                     server.handle_spacenav_msg)
    rospy.Subscriber('/%s/state' % server_type, ApplicationState,
                     server.handle_state_msg)

    # This will translate director messages into /<server_type>/panoid messages
    def handle_director_message(msg):
        asset = get_first_asset_from_activity(msg, server_type)
        if not asset:
            return
        panoid_pub.publish(String(asset))

    rospy.Subscriber('/director/scene', GenericMessage, handle_director_message)

    rospy.spin()

if __name__ == '__main__':
    main()

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
