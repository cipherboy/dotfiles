function find_jars() {
    find /usr -type f -name "*.jar" 2>/dev/null
}

function find_jar() {
    find_jars | grep -i "$1"
}
