/**
	Contains interfaces and enums for evented I/O drivers.

	Copyright: © 2012-2013 RejectedSoftware e.K.
	Authors: Sönke Ludwig
	License: Subject to the terms of the MIT license, as written in the included LICENSE.txt file.
*/
module vibe.core.driver;

public import vibe.core.file;
public import vibe.core.net;
public import vibe.core.sync;
public import vibe.core.stream;
public import vibe.core.task;

import vibe.inet.url;

import core.time;
import std.exception;


/**
	Returns the active event driver
*/
EventDriver getEventDriver(bool ignore_unloaded = false)
{
	assert(ignore_unloaded || s_driver !is null, "No event driver loaded. Did the vibe.core.core module constructor run?");
	return s_driver;
}

/// private
package void setEventDriver(EventDriver driver)
{
	s_driver = driver;
}

package void deleteEventDriver()
{
	// TODO: use destroy() instead
	delete s_driver;
}


private {
	EventDriver s_driver;
}


/**
	Interface for all evented I/O implementations.

	This is the low level interface for all event based functionality. It is
	not intended to be used directly by users of the library.
*/
interface EventDriver {
	/** Starts the event loop.

		The loop will continue to run until either no more event listeners are active or until
		exitEventLoop() is called.
	*/
	int runEventLoop();

	/* Processes all outstanding events, potentially blocking to wait for the first event.
	*/
	int runEventLoopOnce();

	/** Processes all outstanding events if any, does not block.
	*/
	bool processEvents();

	/** Exits any running event loop.
	*/
	void exitEventLoop();

	/** Opens a file on disk with the speficied file mode.
	*/
	FileStream openFile(Path path, FileMode mode);

	/** Starts watching a directory for changes.
	*/
	DirectoryWatcher watchDirectory(Path path, bool recursive);

	/** Resolves the given host name or IP address string.
	*/
	NetworkAddress resolveHost(string host, ushort family, bool use_dns);

	/** Establiches a tcp connection on the specified host/port.

		'host' can be a DNS name or an IPv4 or IPv6 address string.
	*/
	TCPConnection connectTCP(string host, ushort port);

	/// Deprecated compatibility alias
	deprecated("Please use connectTCP instead.") alias connectTcp = connectTCP;

	/** Listens on the specified port and interface for TCP connections.

		'bind_address' must be an IPv4 or IPv6 address string corresponding to a local network
		interface. conn_callback is called for every incoming connection, each time from a
		new task.
	*/
	TCPListener listenTCP(ushort port, void delegate(TCPConnection conn) conn_callback, string bind_address, TCPListenOptions options);

	/// Deprecated compatibility alias
	deprecated("Please use listenTCP instead.") alias listenTcp = listenTCP;

	/** Creates a new UDP socket and sets the specified address/port as the destination for packets.

		If a bind port is specified, the socket will be able to receive UDP packets on that port.
		Otherwise, a random bind port is chosen.
	*/
	UDPConnection listenUDP(ushort port, string bind_address = "0.0.0.0");

	/// Deprecated compatibility alias
	deprecated("Please use listenUDP instead.") alias listenUdp = listenUDP;

	/** Creates a new manually triggered event.
	*/
	ManualEvent createManualEvent();

	/** Creates an event for waiting on a non-bocking file handle.
	*/
	FileEvent createFileEvent(int file_descriptor, FileEvent.Event events);

	/// Deprecated compatibility alias
	deprecated("Please use createNanualEvent instead.") alias createSignal = createManualEvent;

	/** Creates a new timer.

		The timer can be started by calling rearmTimer() with a timeout.
		The initial reference count is 1, use releaseTimer to free all resources
		associated with the timer.
	*/
	size_t createTimer(void delegate() callback);

	/// Increases the reference count by one.
	void acquireTimer(size_t timer_id);

	/// Decreases the reference count by one.
	void releaseTimer(size_t timer_id);

	/// Queries if the timer is currently active.
	bool isTimerPending(size_t timer_id);

	/// Resets the timeout of the timer.
	void rearmTimer(size_t timer_id, Duration dur, bool periodic);

	/// Stops the timer.
	void stopTimer(size_t timer_id);

	/// Waits for the pending timer to expire.
	void waitTimer(size_t timer_id);
}


/**
	Provides an event driver with core functions for task/fiber control.
*/
interface DriverCore {
	@property void eventException(Exception e);
	void yieldForEvent();
	void resumeTask(Task f, Exception event_exception = null);
	void notifyIdle();
}

interface FileEvent {
	enum Event {
		none = 0,
		read = 1<<0,
		write = 1<<1,
		signal = 1<<2,
		any = read|write|signal
	}
	
	void wait(Event which = Event.any);
	bool wait(Duration timeout, Event which = Event.any);
}
