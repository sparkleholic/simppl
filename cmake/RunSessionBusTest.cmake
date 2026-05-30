if(NOT DEFINED TEST_EXECUTABLE)
    message(FATAL_ERROR "TEST_EXECUTABLE is not set")
endif()

if(APPLE AND "$ENV{DBUS_SESSION_BUS_ADDRESS}" STREQUAL "")
    execute_process(
        COMMAND id -u
        OUTPUT_VARIABLE USER_ID
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE ID_RESULT
    )
    if(NOT ID_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to determine the current user id")
    endif()

    execute_process(
        COMMAND launchctl print gui/${USER_ID}/org.freedesktop.dbus-session
        OUTPUT_VARIABLE DBUS_SERVICE
        ERROR_VARIABLE DBUS_SERVICE_ERROR
        RESULT_VARIABLE LAUNCHCTL_RESULT
    )
    if(NOT LAUNCHCTL_RESULT EQUAL 0)
        message(FATAL_ERROR
            "Failed to inspect org.freedesktop.dbus-session: "
            "${DBUS_SERVICE_ERROR}"
        )
    endif()

    string(REGEX MATCH
        "path = ([^\n]+unix_domain_listener)"
        DBUS_SOCKET_MATCH
        "${DBUS_SERVICE}"
    )
    if(NOT DBUS_SOCKET_MATCH)
        message(FATAL_ERROR
            "Could not find the DBus launchd socket. "
            "Run `brew services start dbus` and try again."
        )
    endif()

    set(ENV{DBUS_SESSION_BUS_ADDRESS} "unix:path=${CMAKE_MATCH_1}")
endif()

execute_process(
    COMMAND "${TEST_EXECUTABLE}"
    RESULT_VARIABLE TEST_RESULT
)
if(NOT TEST_RESULT EQUAL 0)
    message(FATAL_ERROR
        "${TEST_EXECUTABLE} failed with exit code ${TEST_RESULT}"
    )
endif()
