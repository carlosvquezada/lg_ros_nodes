#!/usr/bin/env python

import time
import rospy
import unittest
from lg_common.msg import AdhocBrowser
from lg_common import AdhocBrowserPool


PKG = 'lg_common'
NAME = 'test_adhoc_browser_pool'


class TestAdhocBrowserPool(unittest.TestCase):
    def setUp(self):
        self.pool = AdhocBrowserPool('center')
        rospy.set_param('rosbridge_secure', True)
        rospy.set_param('rosbridge_port', 1234)

    def tearDown(self):
        pass

    def test_rosbridge_params_passed(self):
        test_browser_msg = AdhocBrowser()

        self.pool._create_browser('test_test', test_browser_msg)
        assert self.pool.browsers['test_test'] is not None

        url = self.pool.browsers['test_test'].url
        assert 'ros_instance_name=test_test' in url
        assert 'rosbridge_secure' in url
        assert 'rosbridge_port' in url

if __name__ == '__main__':
    rospy.init_node(NAME)
    import rostest
    rostest.rosrun(PKG, NAME, TestAdhocBrowserPool)
