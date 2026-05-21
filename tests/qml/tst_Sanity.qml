import QtQuick
import QtTest

TestCase {
    name: "Sanity"

    function test_pass() {
        compare(1 + 1, 2)
    }
}
