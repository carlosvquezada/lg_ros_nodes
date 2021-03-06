#include "ros/ros.h"
#include <string>
#include <vector>
#include <linux/input.h>

#include "lg_common/StringArray.h"
#include "lg_mirror/EvdevEvents.h"
#include "ros_event_relay.h"
#include "uinput_device.h"
#include "viewport_mapper.h"

using lg_common::StringArray;
using lg_common::StringArrayPtr;

/**
 * \brief Constructor
 * \param node_handle ROS node handle.
 * \param viewport_name Name of the viewport we are handling.
 * \param device Uinput device awaiting event messages.
 * \param events_topic Topic name for event routing.
 * \param mapper Xinput mapper for viewport.
 */
RosEventRelay::RosEventRelay(
    ros::NodeHandle node_handle,
    const std::string& viewport_name,
    UinputDevice device,
    const std::string& events_topic,
    ViewportMapper mapper,
    bool auto_zero
):
  n_(node_handle),
  viewport_name_(viewport_name),
  device_(device),
  events_topic_(events_topic),
  mapper_(mapper),
  auto_zero_(auto_zero),
  routing_(false),
  should_idle_remap_(true)
{}

/**
 * \brief Handle a change in event routing.
 * \param msg List of viewports that should receive touches.
 */
void RosEventRelay::HandleRouterMessage(const StringArrayPtr& msg) {
  ROS_DEBUG("Got router message");
  bool should_route = false;
  std::size_t num_viewports = msg->strings.size();
  for (std::size_t i = 0; i < num_viewports; i++) {
    ROS_DEBUG_STREAM("Comparing " << viewport_name_ << " to " << msg->strings[i]);
    if (msg->strings[i] == viewport_name_) {
      should_route = true;
      break;
    }
  }

  if (should_route) {
    ROS_DEBUG("should route");
    OpenRoute_();
  } else {
    ROS_DEBUG("should not route");
    CloseRoute_();
  }
}

/**
 * \brief Begin routing events to device and map to viewport.
 *
 * If viewport mapping fails, events will not be routed.
 *
 * Otherwise, this method idempotently sets the state of this relay.
 */
void RosEventRelay::OpenRoute_() {
  try {
    mapper_.Map();
  } catch(ViewportMapperExecError& e) {
    ROS_ERROR_STREAM("Mapping viewport exec error: " << e.what());
    return;
  } catch(ViewportMapperStringError& e) {
    ROS_ERROR_STREAM("Mapping viewport string error: " << e.what());
    return;
  }

  if (routing_) {
    return;
  }
  routing_ = true;
  router_sub_ = n_.subscribe(events_topic_, 10, &RosEventRelay::HandleEventMessage, this);
}

void RosEventRelay::HandleEventMessage(const lg_mirror::EvdevEvents::Ptr& msg) {
  if (should_idle_remap_) {
    ROS_DEBUG("idle remapping");
    should_idle_remap_ = false;
    try {
      mapper_.Map();
    } catch(ViewportMapperExecError& e) {
      ROS_ERROR_STREAM("Mapping viewport exec error: " << e.what());
    } catch(ViewportMapperStringError& e) {
      ROS_ERROR_STREAM("Mapping viewport string error: " << e.what());
    }
  }
  device_.HandleEventMessage(msg);
  idle_remap_timer_ = n_.createTimer(ros::Duration(1.0), &RosEventRelay::ResetIdleRemap, this, true);
}

void RosEventRelay::ResetIdleRemap(const ros::TimerEvent& tev) {
  ROS_DEBUG("reset idle remap");
  should_idle_remap_ = true;
}

/**
 * Stop routing events to device.
 *
 * Idempotently clears the state of this relay.
 */
void RosEventRelay::CloseRoute_() {
  if (!routing_) {
    return;
  }
  routing_ = false;
  router_sub_.shutdown();

  if (auto_zero_) {
    device_.Zero();
  }
}
