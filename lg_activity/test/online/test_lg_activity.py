#!/usr/bin/env python

PKG = 'lg_activity'
NAME = 'test_lg_activity'

import rospy
import unittest


# ActivitySource - a class that wraps source
# ActivitySourceDetector returns list of ActivitySources
# ActivityTracker subscribes to topics from ActivitySources and runs ActivitySources checks on them

from lg_activity import ActivitySource
from lg_activity import ActivityTracker
from lg_activity import ActivitySourceDetector
from lg_common.helpers import unpack_activity_sources


ACTIVITY_TRACKER_PARAM = '/spacenav/twist:geometry_msgs/Twist:delta'


class SpaceNavMockSource:
    source = {
        "topic": "/spacenav/twist",
        "msg_type": "geometry_msgs/Twist",
        "strategy": "delta",
        "slot": None,
        "value_min": None,
        "value_max": None
    }


class TouchscreenMockSource:
    source = {
        "topic": "/touchscreen/touch",
        "msg_type": "interactivespaces_msgs/String",
        "strategy": "activity",
        "slot": None,
        "value": None,
        "value_min": None,
        "value_max": None
    }


class ProximitySensorMockSource:
    source = {
        "topic": "/proximity_sensor/distance",
        "msg_type": "std_msgs/Float32",
        "strategy": "value",
        "slot": None,
        "value": None,
        "value_min": 10,
        "value_max": 20
    }


class TestActivityTracker(unittest.TestCase):
    def setUp(self):
        """
            Scenario:
            Test ActivitySource:
                - instantiate and run basic asserts on the attributes
            Test ActivitySourceDetector:
                - check whether
            Test ActivityTracker:
                - test delta
                - test activity
                - test value() (TODO)
        """
        self.detector = ActivitySourceDetector(ACTIVITY_TRACKER_PARAM)
        self.sources = self.detector.get_sources()
        self.topic = '/spacenav/twist'
        self.message_type = 'geometry_msgs/Twist'
        self.callback = foo_cb
        self.strategy = 'delta'
        self.activity_source_spacenav_delta = ActivitySource(topic=self.topic,
                                                             message_type=self.message_type,
                                                             callback=self.callback,
                                                             strategy=self.strategy)

    def test_detector_instantiated(self):
        """
        Checks whether detector got instantiated with proper sources
        """
        self.assertEqual(self.detector.__class__.__name__, ActivitySourceDetector.__name__)
        self.assertDictEqual(self.detector.get_source('/spacenav/twist'), SpaceNavMockSource.source)
        self.assertEqual(type(self.detector.sources), list)
        self.assertEqual(type(self.detector.sources[0]), dict)

    def test_tracker(self):
        self.assertEqual(1, 1)


def foo_cb(msg):
    """Do nothing callback"""
    pass

if __name__ == '__main__':
    import rostest
    rostest.rosrun(PKG, NAME, TestActivityTracker)