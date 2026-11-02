ExternalProject_Add(glad
    GIT_REPOSITORY https://github.com/Dav1dde/glad.git
    GIT_RESET 0a7cf1af9e25e02821587bd4095807fc90b6426a
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--filter=tree:0"
    GIT_REMOTE_NAME origin
    GIT_TAG glad2
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

force_rebuild_git(glad)
cleanup(glad install)
