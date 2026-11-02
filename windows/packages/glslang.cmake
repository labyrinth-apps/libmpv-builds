ExternalProject_Add(glslang
    GIT_REPOSITORY https://github.com/KhronosGroup/glslang.git
    GIT_RESET 1309390fdbc3aaa96abad02190772bf7cdf25331
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !Test"
    GIT_REMOTE_NAME origin
    GIT_TAG main
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

force_rebuild_git(glslang)
cleanup(glslang install)
