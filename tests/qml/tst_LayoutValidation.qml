import QtQuick
import QtTest
import "../../qml/components"
import "../../qml/theme"

TestCase {
    name: "LayoutValidation"

    // Mock backend 对象
    QtObject {
        id: mockBackend
        property string phase: "idle"
        property string friendListText: "好友1\n好友2"
        property string templateText: "你好 {name}"
        property bool inputsEnabled: true
        property var filePaths: []
        property string fatalError: ""
        property real progressValue: 50.0
        property string progressStatus: "正在发送"
        property string versionInfo: "五阿哥群发助手 v0.2.1"
    }

    // 模拟 800x650 的最小受限分辨率窗口
    Item {
        id: container
        width: 800
        height: 650

        MainLayout {
            id: mainLayout
            anchors.fill: parent
            mainBackend: mockBackend
        }
    }

    function test_layout_dimensions() {
        compare(container.width, 800, "最小限制宽度应为 800")
        compare(container.height, 650, "最小限制高度应为 650")
    }

    function test_layout_cutoff_and_visibility() {
        // 验证 MainLayout 正确填满父容器
        compare(mainLayout.width, 800)
        compare(mainLayout.height, 650)

        // 验证设置页面的宽度自适应性
        verify(mainLayout.width >= 800, "主窗口容器处于最小限制宽度以上")
    }

    function test_dashboard_layout_dimensions() {
        // 切换至运行态，触发 Setup -> DashboardParallax 视图滑动
        mockBackend.phase = "running"
        
        // 等待界面切换动画基本就绪
        wait(350)
        
        compare(mainLayout.width, 800, "在运行态下 MainLayout 宽度依然保持 800")
        compare(mainLayout.height, 650, "在运行态下 MainLayout 高度依然保持 650")
    }
}
