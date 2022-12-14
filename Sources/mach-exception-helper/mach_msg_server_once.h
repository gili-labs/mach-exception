//
// Copyright © 2022 Gili Labs. All rights reserved.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// mach-exception
// mach_msg_server_once.h
// Created by Patrick Gili on 6/15/22.
//

#ifndef mach_msg_server_once_h
#define mach_msg_server_once_h

mach_msg_return_t
mach_msg_server_once_with_timeout(boolean_t (*demux)(mach_msg_header_t *, mach_msg_header_t *),
                                  mach_msg_size_t max_size,
                                  mach_port_t rcv_name,
                                  mach_msg_options_t options,
                                  mach_msg_timeout_t timeout);

#endif /* mach_msg_server_once_h */
