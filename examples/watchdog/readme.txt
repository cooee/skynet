skynet 笔记

先在阿里云上网络安全组配置进出口端口，不然连接不上

1. 按照教程編譯，需要注意的是skynet lua  使用5.3 支持最新的位運算，如果使用bit 可以参考（https://www.cnblogs.com/Jackie-Snow/p/7122037.html

对于luabitop，skynet自带的lua5.3源码已经支持（在lbitlib.c文件中），但是默认是关闭的，修改lua5.3的Makefile，增加LUA_COMPAT_BITLIB宏并重新编译：

MYCFLAGS=-I../../skynet-src -g -DLUA_COMPAT_BITLIB
这样在bit.lua中对bit32就能正确引用了。

2. 关于skynet 服务(service)
	skynet以服务为基本单位和入口，每个服务有自己的lua虚拟机（沙盒保护），所以所需文件都得自己加载，也可以配置默认loader

	lualoader = root .. "lualib/loader.lua"

	skynet服务的本质

	每个skynet服务都是一个lua state，也就是一个lua虚拟机实例。而且，每个服务都是隔离的，各自使用自己独立的内存空间，服务之间通过发消息来完成数据交换。

	lua state本身没有多线程支持的，为了实现cpu的摊分，skynet实现上在一个线程运行多个lua state实例。而同一时间下，调度线程只运行一个服务实例。为了提高系统的并发性，skynet会启动一定数量的调度线程。同时，为了提高服务的并发性，就利用lua协程并发处理。

	所以，skynet的并发性有3点：

	1、多个调度线程并发
	2、lua协程并发处理
	3、服务调度的切换

	 

	skynet服务的设计基于Actor模型。有两个特点：

	1. 每个Actor依次处理收到的消息
	2. 不同的Actor可同时处理各自的消息

	实现上，cpu会按照一定规则分摊给每个Actor，每个Actor不会独占cpu，在处理一定数量消息后主动让出cpu，给其他进程处理消息。


3. lua文件加载搜索路径配置
	lua_path = root.."lualib/?.lua;"..root.."lualib/?/init.lua;"..root.."lualib/LuaKit/?.lua;" .. root.."examples/watchdog/?.lua;".. root.."examples/watchdog/gameServer/?.lua;"

4. 关于skynet gate协议模型
	skynet 默认支持两个字节包头（https://blog.codingnow.com/2015/01/skynet_netpack.html）
	所以基本写包如下
	--[[--
	设置包头处理
	]]
	function GameSocket:onWriteHead(cmd,bodyLen)
		-- error("需要自行实现读包头接口")
		local len  = 4 + bodyLen;
		local head = struct.pack('>I2I4',len,cmd);--两个字节包头
		return head;
	end

	读包
	function GameSocket:onReadHead(sock)
		local headBuf, receive_status = sock:receive(6)
	    if receive_status == "closed" or headBuf == nil then
	        return receive_status;
	    end
	    local len,cmd,type,position
	    position = 1
	    len,cmd,position = struct.unpack('>I2I4',headBuf,position)
	    local bodyLen = len - 6;
		return receive_status,cmd,bodyLen;
	end


5. 关于 watchdog gate agent
	watchdog 看门狗 入口 ，负责启动 gate 服务，管理socket相关异常指令
	gate 网关服务 默认包头2字节 后面是包体，gate主要负责管理连接，所有连接都由gate处理，记录了所有的socket连接，然后分发到agent
	agent 代理服务器，每个连接过来都由一个代理服务器负责后续的解包，分发

6 关于集群
	后续补充
