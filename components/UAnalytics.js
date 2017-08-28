/**
 * Created by wangfei on 17/8/28.
 */
import React, { Component } from 'react';
import {
    AppRegistry,
    StyleSheet,
    Text,
    Button,
    TouchableOpacity,
    AsyncStorage,
    View
} from 'react-native';
import ColorUtil from './ColorUtil'
import { StackNavigator } from 'react-navigation';
import APP from './UAnalytics_app'
import Game from './UAnalytics_game'
class AnalyticsMain extends Component {


    render() {
        const { navigate } = this.props.navigation;
        return (
            <View style={styles.u_c}>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={() => navigate('APP', {user: ''})}
                >
                    <Text style={styles.u_c_text}>{'应用统计'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={() => navigate('Game', {user: ''})}
                >
                    <Text style={styles.u_c_text}>{'游戏统计'}</Text>
                </TouchableOpacity>

            </View>
        );
    }
}
const ShareNav = StackNavigator({
    AnalyticsMain: {screen: AnalyticsMain},
    APP: {screen: APP,
        navigationOptions:
            {
                headerTitle:'应用统计',
                headerStyle: {
                    backgroundColor: ColorUtil.default_primary_color,
                    // height:360
                },
                titleStyle: {
                    color: ColorUtil.text_primary_color,
                    textAlign: 'center',
                },
                headerTitleStyle:{
                    alignSelf:'center',
                    color:  ColorUtil.text_primary_color,
                },

            }},
    Game: {screen: Game,
        navigationOptions:
            {
                headerTitle:'游戏统计',
                headerStyle: {
                    backgroundColor: ColorUtil.default_primary_color,
                    // height:360
                },
                titleStyle: {
                    color: ColorUtil.text_primary_color,
                    textAlign: 'center',
                },
                headerTitleStyle:{
                    alignSelf:'center',
                    color:  ColorUtil.text_primary_color,
                },

            }},


}, {
    initialRouteName: 'AnalyticsMain', // 默认显示界面
    mode: 'card',  // 页面切换模式, 左右是card(相当于iOS中的push效果), 上下是modal(相当于iOS中的modal效果)
    headerMode: 'screen', // 导航栏的显示模式, screen: 有渐变透明效果, float: 无透明效果, none: 隐藏导航栏

});
const styles = StyleSheet.create({
    u_c: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'stretch',
        backgroundColor: ColorUtil.background,
    },
    u_c_item: {
        margin: 10,
        backgroundColor: ColorUtil.default_primary_color,
        elevation: 10,
        borderColor: ColorUtil.default_primary_color,
        borderRadius: 15,
        borderWidth: 1.5,
        shadowOffset: {width: 0, height: 0},
        shadowColor: ColorUtil.default_primary_color,
        shadowOpacity: 1,
        shadowRadius: 5,
        justifyContent: 'center',
        alignItems: 'center',

    },
    u_c_text: {
        fontSize:26,

        color: ColorUtil.text_primary_color
    },
});
export default ShareNav;