function build() {
    local which_ninja="$(which ninja 2>/dev/null)"
    if [ "x$which_ninja" == "x" ]; then
        which_ninja="$(which ninja-build 2>/dev/null)"
    fi

    local which_clang="$(which clang 2>/dev/null)"
    local which_clangpp="$(which clang++ 2>/dev/null)"

    local do_clean="false"
    local do_prep="false"
    local do_build="false"
    local do_test="false"
    local do_popd="true"
    local use_clang="false"
    local use_parallel="true"
    local cmake_args=""
    local make_args=""
    local ninja_args=""
    local ctest_args=""
    local cflags="$CFLAGS"
    local cxxflags="$CXXFLAGS"
    local ccpath="$(which gcc 2>/dev/null)"
    local cxxpath="$(which g++ 2>/dev/null)"
    local py2path="$(which python2 2>/dev/null)"
    local py3path="$(which python3 2>/dev/null)"
    local pypath="$py3path"
    local starting_dir="$(pwd 2>/dev/null)"
    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)"

    for arg in "$@"; do
        if [ "x$arg" == "xclean" ]; then
            do_clean="true"
        elif [ "x$arg" == "xprep" ]; then
            do_prep="true"
        elif [ "x$arg" == "xbuild" ]; then
            do_build="true"
        elif [ "x$arg" == "xtest" ]; then
            do_test="true"
        elif [ "x$arg" == "xall" ]; then
            do_clean="true"
            do_prep="true"
            do_build="true"
            do_test="true"
        elif [ "x$arg" == "xclang" ]; then
            use_clang="true"
        elif [ "x$arg" == "xdebug" ]; then
            cmake_args="$cmake_args -DCMAKE_BUILD_TYPE=Debug"
            ctest_args="$ctest_args --debug"
            cflags="$cflags -Og -ggdb"
            cxxflags="$cxxflags -Og -ggdb"
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

    if [ "$do_clean" == "false" ] && [ "$do_prep" == "false" ] && [ "$do_build" == "false" ] && [ "$do_test" == "false" ]; then
        do_clean="true"
        do_prep="true"
        do_build="true"
    fi

    if [ $use_clang ] && [ "x$which_clang" == "x" ]; then
        use_clang=false
    fi

    if [ "$use_clang" == "true" ]; then
        if [ "x$which_clang" != "x" ]; then
            ccpath="$which_clang"
        fi
        if [ "x$which_clangpp" != "x" ]; then
            cxxpath="$which_clangpp"
        fi
    fi

    if [ "$use_parallel" == "true" ]; then
        local num_cores="$(grep -c '^processor[[:space:]]*:' < /proc/cpuinfo)"
        num_cores=$(( num_cores + 2 ))
        make_args="$make_args -j $num_cores"
        ninja_args="$ninja_args -j $num_cores"
        ctest_args="$ctest_args -j $num_cores"
    else
        make_args="$make_args -j 1"
        ninja_args="$ninja_args -j 1"
        ctest_args="$ctest_args -j 1"
    fi

    cmake_args="$cmake_args -DCMAKE_C_COMPILER=$ccpath -DCMAKE_CXX_COMPILER=$cxxpath -DPYTHON_EXECUTABLE=$pypath -DSSG_JINJA2_CACHE_DIR=~/.ssg_jinja_cache"

    function __build_cd() {
        if [ "x$git_root" == "x" ]; then
            return
        fi

        if [ "x$starting_dir" != "x$git_root" ]; then
            cd "$git_root" || return
        fi
    }

    function __build_info() {
        echo "start dir: $starting_dir"
        echo "git root: $git_root"
        echo "cc path: $ccpath"
        echo "cflags: $cflags"
        echo "cxx path: $cxxpath"
        echo "cxxflags: $cxxflags"
        echo "python path: $pypath"
        echo "do_clean: $do_clean"
        echo "do_prep: $do_prep"
        echo "do_build: $do_build"
        echo "do_test: $do_test"
    }

    function __build_clean_cmake() {
        local have_build_gitkeep=false
        if [ -e "build/.gitkeep" ]; then
            have_build_gitkeep=true
        fi

        (rm -rf build && mkdir -p build) || return 1
        if [ $have_build_gitkeep ]; then
            touch .gitkeep
        fi
    }

    function __build_clean_make() {
        make clean distclean
        return $?
    }

    function __build_clean_python() {
        $pypath setup.py clean || return $?
        if [ -d "build" ]; then
            rm -rf build
        fi
        return 0
    }

    function __build_clean() {
        if [ -e "CMakeLists.txt" ]; then
            __build_clean_cmake
            return $?
        elif [ -e "Makefile" ]; then
            __build_clean_make
            return $?
        elif [ -e "setup.py" ]; then
            __build_clean_python
            return $?
        elif [ -e "src" ]; then
            pushd src || return 1
            __build_clean
            local ret=$?
            popd
            return $ret
        fi
        return 0
    }

    function __build_prep_cmake_ninja() {
        CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p cmake $cmake_args -G Ninja ..
        return $?
    }

    function __build_prep_cmake_make() {
        CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p cmake $cmake_args -G "Unix Makefiles" ..
        return $?
    }

    function __build_prep_cmake() {
        if [ -d "build" ]; then
            cd build || return 1
        fi

        if [ "x$which_ninja" == "x" ]; then
            echo "Prepping with cmake/make"
            __build_prep_cmake_make
            return $?
        else
            echo "Prepping with cmake/ninja"
            __build_prep_cmake_ninja
            return $?
        fi
    }

    function __build_prep_autotools() {
        if [ ! -e "configure" ]; then
            time -p autoreconf -f -i
        fi
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" time -p ./configure
        return $?
    }

    function __build_prep_python_setuptools() {
        $pypath -m pip install --user -r test-requirements.txt
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" $pypath setup.py check
        return $?
    }

    function __build_prep() {
        if [ -e "CMakeLists.txt" ]; then
            __build_prep_cmake
            return $?
        elif [ -e "configure.ac" ] || [ -e "configure.in" ]; then
            __build_prep_autotools
            return $?
        elif [ -e "setup.py" ]; then
            __build_prep_python_setuptools
            return $?
        elif [ -d "src" ]; then
            pushd src || return
            __build_prep
            local ret=$?
            popd
            return $ret
        else
            echo "Cannot build: unknown build system"
            return 1
        fi
    }

    function __build_make() {
        time -p make $make_args
        return $?
    }

    function __build_ninja() {
        time -p $which_ninja $ninja_args
        return $?
    }

    function __build_python() {
        CC="$ccpath" CXX="$cxxpath" CFLAGS="$cflags" CXXFLAGS="$cxxflags" $pypath setup.py build
        return $?
    }

    function __build() {
        if [ "x$which_ninja" != "x" ] && [ -e "build.ninja" ]; then
            echo "Building with ninja"
            __build_ninja
            return $?
        elif [ -e "Makefile" ]; then
            echo "Building with make"
            __build_make
            return $?
        elif [ -e "setup.py" ]; then
            echo "Building with setup.py"
            __build_python
            return $?
        elif [ -d "build" ]; then
            pushd build || return 1
            __build
            local ret=$?
            popd
            return $ret
        elif [ -d "src" ]; then
            pushd src || return 1
            __build
            local ret=$?
            popd
            return $ret
        else
            echo "Unknown build system!"
            return 1
        fi
    }

    function __build_test_ctest() {
        time -p ctest $ctest_args
        return $?
    }

    function __build_test_make() {
        time -p make check
        return $?
    }

    function __build_test_python() {
        time -p $pypath setup.py test
        return $?
    }

    function __build_test() {
        if [ -e "CMakeCache.txt" ]; then
            __build_test_ctest
            return $?
        elif [ -e "Makefile" ]; then
            __build_test_make
            return $?
        elif [ -e "setup.py" ]; then
            __build_test_python
            return $?
        elif [ -d "build" ]; then
            pushd build || return 1
            __build_test
            local ret=$?
            popd
            return $ret
        elif [ -d "src" ]; then
            pushd src || return 1
            __build_test
            local ret=$?
            popd
            return $ret
        else
            echo "Unknown test system!"
            return 1
        fi
    }

    function __build_uncd() {
        local cpwd="$(pwd 2>/dev/null)"

        if [ "x$cpwd" != "x" ] && [ "x$cpwd" != "x$starting_dir" ]; then
            cd "$starting_dir" || return
        fi
    }

    __build_cd
    __build_info

    if [ "$do_clean" == "true" ]; then
        __build_clean
        ret="$?"
        if (( ret != 0 )); then
            echo "Clean failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_prep" == "true" ]; then
        __build_prep
        ret="$?"
        if (( ret != 0 )); then
            echo "Prep failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_build" == "true" ]; then
        __build
        ret="$?"
        if (( ret != 0 )); then
            echo "Build failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_test" == "true" ]; then
        __build_test
        ret="$?"
        if (( ret != 0 )); then
            echo "Test failed with status: $ret"
            return $ret
        fi
    fi

    if [ "$do_popd" == "true" ]; then
        __build_uncd
    fi
    return 0
}
