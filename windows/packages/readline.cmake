ExternalProject_Add(readline
    DEPENDS
        termcap
    GIT_REPOSITORY https://git.sailfishos.org/mirror/readline.git
    GIT_RESET f95e81428a77b37d83e56c0c7099956e8a7adfc8
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} CONF=1 <SOURCE_DIR>/configure
        --host=${TARGET_ARCH}
        --prefix=${MINGW_INSTALL_PREFIX}
        --enable-static
        --disable-shared
        --without-curses
        CFLAGS='-DNEED_EXTERN_PC -DS_IFLNK=0120000'
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

cleanup(readline install)
