function build() {
    local which_ninja="$(which ninja 2>/dev/null)"
    if [ "x$which_ninja" == "x" ]; then
        which_ninja="$(which ninja-build 2>/dev/null)"
    fi

    local which_clang="$(which clang 2>/dev/null)"
    local which_clangpp="$(which clang++ 2>/dev/null)"

    local do_prep="false"
    local do_build="false"
    local do_debug="false"
    local do_cmake_debug="false"
    local do_popd="true"
    local use_clang="false"
    local use_parallel="true"
    local cmake_args=""
    local cflags="$CFLAGS"
    local cxxflags="$CXXFLAGS"
    local ccpath="$(which gcc 2>/dev/null)"
    local cxxpath="$(which g++ 2>/dev/null)"
    local py2path="$(which python2 2>/dev/null)"
    local py3path="$(which python3 2>/dev/null)"
    local pypath="$py3path"
    local starting_dir="$(pwd 2>/dev/null)"

    for arg in "$@"; do
        if [ "x$arg" == "xprep" ]; then
            do_prep="true"
        elif [ "x$arg" == "xbuild" ]; then
            do_build="true"
        elif [ "x$arg" == "xclang" ]; then
            use_clang="true"
        elif [ "x$arg" == "xdebug" ]; then
            cmake_args="$cmake_args -DCMAKE_BUILD_TYPE=Debug"
            cflags="$cflags -Og -ggdb"
            cxxflags="$cxxflags -Og -ggdb"
            do_debug="true"
        elif [ "x$arg" == "xoptimized" ]; then
            cflags="$cflags -O3"
            cxxflags="$cxxflags -O3"
        elif [ "x$args" == "xwarnings" ]; then
            cflags="$cflags -Wall -Wextra -Werror"
            cxxflags="$cxxflags -Wall -Wextra -Werror"
        elif [ "x$arg" == "xmake" ]; then
            which_ninja=""
        elif [ "x$arg" == "xserial" ]; then
            use_parallel="false"
        elif [ "x$arg" == "xpython2" ]; then
            pypath="$py2path"
        elif [ "x$arg" == "xpython3" ]; then
            pypath="$py3path"
        elif [ "x$arg" == "xnopop" ]; then
            do_popd="false"
        fi
    done

    if [ "$do_prep" == "false" ] && [ "$do_build" == "false" ]; then
        do_prep="true"
        do_build="true"
    fi

    if [ $use_clang ] && [ "x$which_clang" == "x" ]; then
        use_clang=false
    fi

    if [ "$use_clang" == "true" ]; then
        if [ "x$which_clang" != "x" ]; then
            ccpath="$which_clang"
        elif [ "x$which_clangpp" != "x" ]; then
            cxxpath="$which_clangpp"
        fi
    fi

    cmake_args="$cmake_args -DCMAKE_C_COMPILER=$ccpath -DCMAKE_CXX_COMPILER=$cxxpath -DPYTHON_EXECUTABLE=$pypath -DSSG_JINJA2_CACHE_DIR=~/.ssg_jinja_cache"

    function __build_cd() {
        local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
        if [ "x$git_root" == "x" ]; then
            return
        fi

        if [ "x$starting_dir" != "x$git_root" ]; then
            cd "$git_root"
        fi
    }

    function __build_prep_cmake_ninja() {
        CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p cmake $cmake_args -G Ninja ..
    }

    function __build_prep_cmake_make() {
        CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p cmake $cmake_args -G "Unix Makefiles" ..
    }

    function __build_prep_cmake() {
        local have_build_gitkeep=false
        if [ -e "build/.gitkeep" ]; then
            have_build_gitkeep=true
        fi

        rm -rf build && mkdir -p build && cd build
        if [ $have_build_gitkeep ]; then
            touch .gitkeep
        fi

        if [ "x$which_ninja" == "x" ]; then
            echo "Prepping with cmake/make"
            __build_prep_cmake_make
        else
            echo "Prepping with cmake/ninja"
            __build_prep_cmake_ninja
        fi
    }

    function __build_prep_autotools() {
        if [ -e "Makefile" ]; then
            make distclean
        fi

        if [ ! -e "configure" ]; then
            time -p autoreconf -f -i
        fi
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p ./configure
    }

    function __build_prep_python_setuptools() {
        if [ -d "build" ]; then
            $pypath ./setup.py clean
            rm -rf "build"
        fi
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" $pypath ./setup.py check
    }

    function __build_prep() {
        if [ -e "CMakeLists.txt" ]; then
            __build_prep_cmake
        elif [ -e "configure.ac" ] || [ -e "configure.in" ]; then
            __build_prep_autotools
        elif [ -e "setup.py" ]; then
            __build_prep_python_setuptools
        elif [ -d "src" ]; then
            cd src
            __build_prep
        else
            echo "Cannot build: unknown build system"
        fi
    }

    function __build_make() {
        time -p make
    }

    function __build_ninja() {
        time -p $which_ninja
    }

    function __build_python() {
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" $pypath ./setup.py build
    }

    function __build() {
        if [ "x$which_ninja" != "x" ] && [ -e "build.ninja" ]; then
            echo "Building with ninja"
            __build_ninja
        elif [ -e "Makefile" ]; then
            echo "Building with make"
            __build_make
        elif [ -e "setup.py" ]; then
            echo "Building with setup.py"
            __build_python
        elif [ -d "build" ]; then
            cd build
            __build
        elif [ -d "src" ]; then
            cd src
            __build
        else
            echo "Unknown build system!"
        fi
    }

    function __build_uncd() {
        local cpwd="$(pwd 2>/dev/null)"

        if [ "x$cpwd" != "x" ] && [ "x$cpwd" != "x$starting_dir" ]; then
            cd "$starting_dir"
        fi
    }

    __build_cd

    if [ "$do_prep" == "true" ]; then
        __build_prep
    fi
    if [ "$do_build" == "true" ]; then
        __build
    fi

    if [ "$do_popd" == "true" ]; then
        __build_uncd
    fi
}
