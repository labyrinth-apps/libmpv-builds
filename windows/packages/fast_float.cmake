ExternalProject_Add(fast_float
    GIT_REPOSITORY https://github.com/fastfloat/fast_float.git
    GIT_RESET dbeabeeb3e6791cb96994c2a7a084c36e62ccfb2
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    GIT_REMOTE_NAME origin
    GIT_TAG main
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

force_rebuild_git(fast_float)
cleanup(fast_float install)
