% @page mexHID
% @section mexHID mexHID()
% @par
% mexHID() is a mex function for connecting to USB Human Interface Devices.
% These devices include many common devices like keyboards, mouses, and
% joysticks, and other devices including some digital-analog converters.
% @par
% This document assumes you have some familiarity with USB and HID.  Here
% are a few key concepts:
%   - @b host The USB host is hardware in your machine and software in
%   your opertating system that control USB devices.
%   - @b device USB and HID devices are things you attache to the host,
%   like keyboards.  Some devices are composites of several sub-devices.
%   - @b element HID devices have elements, like buttons, motion axes,
%   LEDs, and other discrete pieces.
%   - @b report The host and HID devices communicate by sending reports to
%   each other.  Reports are organized arrays with specific IDs and
%   destinations.  One report can contain data about many elements.
%   - @b frame The USB host chops time into frames.  Some devices use
%   frames of 1 millisecond.  Others use frames of 125 microseconds.  The
%   frame duration limits the temporal resolution of device communication.
%   .
% @par
% As of November2010, mexHID() is only implemented for Mac OS X 10.5 or
% later.  Since the platform-dependent details are implemented separately
% from the Matlab interface, it would be possible to implement mexHID() for
% other operating systems.
% @section timing Timing
% @par
% mexHID() tries to accounts for the timing of device communications and
% events in a few ways.
% @par
% When mexHID() does a transaciton to communicate with a device (e.g read
% or write a report or element value), it returns four pieces of timing
% information:
%   - the pre-transaction USB host frame number
%   - the pre-transaction USB host frame time
%   - the post-transaction USB host frame number
%   - the post-transaction USB host frame time
%   .
% These values are reported by the USB host in frame-number-frame-time
% pairs.  The pre-post interval should indicate whether the transaction
% happened in a normal, expedient fashion.
% @par
% In tests, the post-transaction frame time tended to align with the change
% in frame number, so it should be a fair estimate of when a device
% acknowledged a transaction and when it should have responded to a
% command.
% @par
% Device events, like button-presses or mouse movements, can happen at any
% time.  It's not practical or efficient to detect these events by polling
% from Matlab m-functions.  Instead, mexHID() uses queues to store events
% and corresponding timetsamps "in the background".  An m-function can
% read and respond to queued events relatively infrequently, without
% missing any individual event.
% @par
% The frame time values and event timestamps are comparable because they
% both come from the same clock.
% @section matching Matching
% @par
% mexHID() uses the concept of "matching" to locate devices:  It accepts a
% struct of device properties and values, compares the given values to
% those of exising devices, and returns identiers for the devices that
% match.  The "matching struct" may be very generous, perhaps allowing any
% keyboard-type device to match, or very strict, perhaps specifying a
% specific keyboard manufacturer, product, and serial number.
% @par
% mexHID() also uses matching to locate elements of a device.  The same
% syntax and logic apply: a matching struct might allow any button-type
% element to match, or may require a singe key, like "f".
% @section helpers Helpers
% @par
% mexHID() has two helpers which are not part of the mexHID() mex function
% itself.
% @par
% mexHIDUsage() is a singelton class which contains tables of standard
% information about how HID devices describe themsleves and how to specify
% devices and elements with certain functions.  For example, mexHIDUsage()
% can tell you that a keyboard has a "Usage" property value of 6 and a
% "UsagePage" property value of 1.  Try "mexHIDUsage.gui" to see lots of
% similar data.
% @par
% The static method mexHIDUsage.gui() opens a figure for quick viewing of
% usage names and values.
% @par
% mexHIDScout() is a function which summarizes all the HID devices
% connected to your host.  It shows a table of devices and their property
% values.  It also has buttons for exploring individual devices and
% observing their input values.
% @section subfunctions Sub-functions
% @par
% mexHID() has many sub-functions.  Typing "mexHID" by itself will
% summarize the sub-functions and their expected inputs and outputs.  This
% sections describes each sub-function in more detal.
% @par
% Each subfunction can be accessed with the syntax
% @code
% [outputs] = mexHID('subfunction', [inputs]);
% @endcode
% Where [outputs] and [inputs] may be zero or more comma-separated values.
% For example,
% @code
% status = mexHID('initialize')
% @endcode
% or
% @code
% [data, timing] = mexHID('readElementValues', deviceID, cookies)
% @endcode
% @section basics mexHID() basics:
% @subsection initialize
% @par
% Needs to be called before the rest of mexHID() will work.
% @par
% inputs
% @par
% outputs
%   - @e status, zero upon success
% .
% @subsection terminate
% @par
% Call to finish with mexHID(): free resources for all devices, elements,
% and queues.  Called automatically when Matlab exits or does "clear mex".
% @par
% inputs
% @par
% outputs
%   - @e status, zero upon success
% .
% @subsection check
% @par
% Allow queued values to be send from "the background" to Matlab, via
% callback functions.  Applies to all queues that are open and started.
% Needs to be called often enough that queues don't fill up.
% @par
% inputs
% @par
% outputs
%   - @e timestamp, the current time in seconds, taken from the same clock
%   as element value times and event timestamps.
% .
% @subsection isInitialized
% @par
% Is mexHID() already initialized?
% @par
% inputs
% @par
% outputs
%   - @e isInitialized, true of mexHID() was already initialized, or else
%   false.
% .
% @section devices mexHID() devices:
% @subsection getOpenedDevices
% @par
% What devices have already been opened?
% @par
% inputs
% @par
% outputs
%   - @e deviceIDs, an array identifiers as returned from
%   openMatchingDevice or openAllMatchingDevices.
%   .
% @subsection summarizeDevices
% @par
% Get properties for all the devices connected to the host.
% @par
% inputs
% @par
% outputs
%   - @e infoStruct, a nx1 struct array of device properties, where n is
%   the number of devices connected to the host.  Each field is a HID
%   device property name.  These properties are suitable for doing device
%   matching.
%   .
% @subsection openMatchingDevice
% @par
% Open a single device that matches the given properties.
% @par
% inputs
%   - @e matchingStruct, a scalar struct with fields that match the device
%   property names returned from summarizeDevices.  Not all properties need
%   be included.  The field values should match the properites of the
%   device to be opened.
%   - @e isExclusive, optional, if true, the device will be "seized" so
%   that other programs and the operating system will not have access to
%   the device and its inputs.  The default is false, do not seize the
%   device.  Exclusive access may fail if the user has insufficient
%   privileges or another program has already seized the same device.
%   .
% @par
% outputs
%   - @e deviceID, a positive scalar identifier that mexHID() uses to refer
%   to the opened device, or a negative scalar on error.
%   .
% @subsection openAllMatchingDevices
% @par
% Open multiple devices that match the given properties.
% @par
% inputs
%   - @e matchingStruct, a scalar struct with fields that match the device
%   property names returned from summarizeDevices.  Not all properties need
%   be included.  The field values should match the properites of the
%   devices to be opened.
%   - @e isExclusive, optional, if true, the devices will be "seized" so
%   that other programs and the operating system will not have access to
%   the them and their inputs.  The default is false, do not seize the
%   devices.  Exclusive access may fail if the user has insufficient
%   privileges or another program has already seized the same devices.
%   .
% @par
% outputs
%   - @e deviceIDs, an array of positive scalar identifiers that mexHID()
%   uses to refer to the opened devices, or a negative scalar on error.
%   .
% @subsection getDeviceProperties
% @par
% Get properties for a particular, opened devices.
% @par
% inputs
%   - @e deviceIDs, an array identifiers as returned from
%   openMatchingDevice or openAllMatchingDevices.
%   .
% @par
% outputs
%   - @e infoStruct, a nx1 struct array of device properties, where n is
%   the number of @e deviceIDs.  Each field is a HID device property name.
%   These properties are suitable for doing device matching.
%   .
% @subsection readDeviceReport
% @par
% Read a full report of data send from the device.  The report will contain
% raw bytes of data that require insider-knowledge about the device to
% undestand.  On OS X 10.5 and 10.6, this doesn't seem to work.  But most
% of the same information is available from individual device elements.
% @par
% inputs
%   - @e deviceID, an identifier as returned from openMatchingDevice or
%   openAllMatchingDevices.
%   - @e reportStruct, a struct containing the type and ID of the report to
%   be read.  May be a nx1 struct array of n reports to be read in
%   immediate succession.  reportStruct must have field names that match
%   the template returned from getReportStructTemplate.
% @par
% outputs
%   - @e reportStruct, a copy of the @e reportStruct input, with report
%   byte data filled in.
%   - @e timing, an nx5 matrix of timing information.  Each row corresponds
%   to an element of @e reportStruct.  The first column contains the ID
%   of the report.  The second column contains the pre-transaction
%   frame number.  The third column contains the pre-transaction
%   frame time.  The fourth column contains the post-transaction frame
%   number.  The fifth column contains the post-transaction frame time.
%   .
% @subsection writeDeviceReport
% @par
% Write a full report of data to the device.  The report must contain
% raw bytes of data that require insider-knowledge about the device to
% assemble.
% @par
% inputs
%   - @e deviceID, an identifier as returned from openMatchingDevice or
%   openAllMatchingDevices.
%   - @e reportStruct, a struct containing the type and ID of the report to
%   be written.  May be a nx1 struct array of n reports to be written in
%   immediate succession.  reportStruct must have field names that match
%   the template returned from getReportStructTemplate.
% @par
% outputs
%   - @e status, zero upon success
%   - @e timing, an nx5 matrix of timing information.  Each row corresponds
%   to an element of @e reportStruct.  The first column contains the ID
%   of the report.  The second column contains the pre-transaction
%   frame number.  The third column contains the pre-transaction
%   frame time.  The fourth column contains the post-transaction frame
%   number.  The fifth column contains the post-transaction frame time.
%   .
% @subsection closeDevice
% @par
% Close devices that were opened, releasing their resources and giving up
% any exclusive access.
% @par
% inputs
%   - @e deviceIDs, an array identifiers as returned from
%   openMatchingDevice or openAllMatchingDevices.
%   .
% @par
% outputs
%   - @e status, zero upon success
%   .
% @section elements mexHID() device elements:
% @subsection summarizeElements
% @par
% Get properties for the elements of a device.
% @par
% inputs
%   - @e deviceID, an identifier as returned from openMatchingDevice or
%   openAllMatchingDevices.
%   - @e matchingStruct, optional, a scalar struct with fields that match
%   the element property names returned from summarizeDevices (without this
%   argument).  Not all properties need be included.  The field values
%   should match the elements to be summarized.
%   .
% @par
% outputs
%   - @e infoStruct, a nx1 struct array of element properties, where n is
%   the number of elements that the device contains, or the number that
%   matched with @e matchingStruct.  Each field is a HID
%   element property name.  These properties are suitable for doing element
%   matching.
%   .
% @subsection findMatchingElements
% @par
% Get "cookies" for elements of a device that match the given properties.
% @par
% inputs
%   - @e deviceID, an identifier as returned from openMatchingDevice or
%   openAllMatchingDevices.
%   - @e matchingStruct, a scalar struct with fields that match
%   the element property names returned from summarizeDevices.  Not all
%   properties need be included.  The field values should match the
%   elements to be found.
%   .
% @par
% outputs
%   - @e cookies, an array of "ElementCookie" identifiers that the device
%   uses to refer to the found elements.
%   .
% @subsection getElementProperties
% @par
% % Get properties for the elements of a device.
% @par
% inputs
%   - @e deviceID, an identifier as returned from openMatchingDevice or
%   openAllMatchingDevices.
%   - @e cookies, nx1 array of "ElementCookie" identifiers as returned from
%   findMatchingElements.
%   - @e propertyNameCell, a cell array of string element property names.
%   The property names must match the element property names returned from
%   summarizeDevices.
%   .
% @par
% outputs
%   - @e infoStruct, a nx1 struct array of element properties, where n is
%   the number of @e cookies.  Each field is an element property name from
%   @e propertyNameCell.
%   .
% @subsection setElementProperties
% @par
% Set the values of device element properties.
% @par
% inputs
%   - @e deviceID, an identifier as returned from openMatchingDevice or
%   openAllMatchingDevices.
%   - @e cookies, nx1 array of "ElementCookie" identifiers as returned from
%   findMatchingElements.
%   - @e propertyValueStruct, a scalar struct with fields that match
%   the element property names returned from summarizeDevices.  Not all
%   properties need be included.  The field values will be assigned to the
%   corresponding property of each element specified in @e cookies.
% @par
% outputs
%   - @e status, zero upon success
%   .
% @subsection readElementValues
% @par
% Read the values of input and feature elements, such as button states and
% motion axis positions.  Note that on OS X 10.5 and 10.6, input element
% values are cached by the host as they change, and reading is very fast.
% @par
% inputs
%   - @e deviceID, an identifier as returned from openMatchingDevice or
%   openAllMatchingDevices.
%   - @e cookies, nx1 array of "ElementCookie" identifiers as returned from
%   findMatchingElements, whose element values to read.
%   .
% @par
% outputs
%   - @e data nx3 matrix of element value data.  Each row corresponds to an
%   element of @e cookies.  The first column contains the element cookie.
%   The second column contains the element's value.  The thrid column
%   contains the timestamp assigned by the host when the element changed to
%   its present value.
%   - @e timing, an nx5 matrix of timing information.  Each row corresponds
%   to an element of @e cookies.  The first column contains the element
%   cookie. The second column contains the pre-transaction
%   frame number.  The third column contains the pre-transaction
%   frame time.  The fourth column contains the post-transaction frame
%   number.  The fifth column contains the post-transaction frame time.
%   .
% @subsection writeElementValues
% @par
% Write the values of output and feature elements, such as LED on/off
% states.
% @par
% inputs
%   - @e deviceID, an identifier as returned from openMatchingDevice or
%   openAllMatchingDevices.
%   - @e cookies, nx1 array of "ElementCookie" identifiers as returned from
%   findMatchingElements, whose element values to write.
%   - @e values, nx1 array of values that correspond to the elements of @e
%   cookies, to be written to each element.
%   .
% @par
%   - @e status, zero upon success
%   - @e timing, an nx5 matrix of timing information.  Each row corresponds
%   to an element of @e cookies.  The first column contains the element
%   cookie. The second column contains the pre-transaction
%   frame number.  The third column contains the pre-transaction
%   frame time.  The fourth column contains the post-transaction frame
%   number.  The fifth column contains the post-transaction frame time.
%   .
% @section queues mexHID() device queues:
% @subsection openQueue
% @par
% Create a queue for holding "in the background" element value changes.
% Each device may use only one queue at a time.
% @par
% inputs
%   - @e deviceID, an identifier as returned from openMatchingDevice or
%   openAllMatchingDevices.
%   - @e cookies, nx1 array of "ElementCookie" identifiers as returned from
%   findMatchingElements, whose element values to keep track of.
%   - @e callbackCell, a cell array containing a callback function.  The
%   first element must be a function handle to invoke when the queue is
%   non-empty and check is called.  The second element must be "context"
%   information to pass as the first argument to the function.  The
%   function handle might be an object method, and the "context" might be
%   an object's handle.  The function should expect as the second argument
%   a matrix of element value data just like the @e data returned from
%   readElementValues.
%   - @e queueDepth, the number of element values that can be kept track of
%   "in the background" without overwriting older values.  The suitable @e
%   queueDepth depends on the number of elements being kept track of, how
%   often each element's value changes, and how often check will be called
%   to pass the value data out of "the background" and into Matlab.
% @par
% outputs
%   - @e status, zero upon success
%   .
% @subsection closeQueue
% @par
% Destroy queues and stop keeping track of element values for some devices.
% @par
% inputs
%   - @e deviceIDs, an array identifiers as returned from
%   openMatchingDevice or openAllMatchingDevices.
% @par
% outputs
%   - @e status, zero upon success
%   .
% @subsection startQueue
% @par
% Start queues to begin or unpause keeping track of element values for some
% devices.
% @par
% inputs
%   - @e deviceIDs, an array identifiers as returned from
%   openMatchingDevice or openAllMatchingDevices.
% @par
% outputs
%   - @e status, zero upon success
%   .
% @subsection stopQueue
% @par
% Stop queues to pause keeping track of element values for some
% devices.
% @par
% inputs
%   - @e deviceIDs, an array identifiers as returned from
%   openMatchingDevice or openAllMatchingDevices.
% @par
% outputs
%   - @e status, zero upon success
%   .
% @subsection flushQueue
% @par
% Ignore and get rid of any data that was previously enqueued for some
% devices.
% @par
% inputs
%   - @e deviceIDs, an array identifiers as returned from
%   openMatchingDevice or openAllMatchingDevices.
% @par
% outputs
%   - @e status, zero upon success
%   .
% @section internals mexHID() internals:
% @subsection getReportStructTemplate
% @par
% Get a scalar struct whose field are those expected by readDeviceReport
% and writeDeviceReport.
% @par
% inputs
% @par
% outputs
%   - @e reportStruct, a scalar struct with the correct field suitable for
%   the @e reportStruct of readDeviceReport and writeDeviceReport, and
%   empty field values.
%   .
% @subsection getNameForReportType
% @par
% Get a human-readable name for a mexHID() report type.
% @par
% inputs
%   - @e reportType, one of the enumerated report types used by mexHID().
%   .
% @par
% outputs
%   - @e name, a string name for a type of report.  If @e reportType is not
%   a valid type of report, returns "unknown".
%   .
% @subsection getReportTypeForName
% @par
% Get a mexHID() report type from a human-readable name.
% @par
% inputs
%   - @e name, a string name for a type of report.
%   .
% @par
% outputs
%   - @e reportType, one of the enumerated report types used by mexHID().
%   If @e name is not a recognized name for a report type, returns -1.
%   .
% @subsection getDescriptionOfReturnValue
% @par
% Get a human-readable description for any of the values returned by
% mexHID(), especially negative scalar @e status values.
% @par
% inputs
%   - @e returnValue, any value, but only meaningful if it was returned
%   from mexHID().
% @par
% outputs
%   - @e description, a human-readable string that describes @e
%   returnValue, as it applies to mexHID().
%   .
%

% @subsection subcommand
% @par
% Description
% @par
% inputs
% @par
% outputs