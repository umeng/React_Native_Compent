/**
 * Created by wangfei on 17/8/28.
 */
import React, { Component } from 'react';
import {
    AppRegistry,
    StyleSheet,
    Text,
    Image,
    View
} from 'react-native';

import { TabNavigator } from 'react-navigation';

import UShare from './UShare'
import Upush from './UPush'
import UAnalytics from './UAnalytics'
import ColorUtil from './ColorUtil'
const Home = TabNavigator({
        UAnalytics: { screen: UAnalytics,
            navigationOptions: {

                tabBarLabel: '统计',
                tabBarIcon: ({tintColor}) => (
                    <Image
                        source={require('./../images/analytics.png')}
                        style={[{tintColor: tintColor},styles.icon]}
                    />
                ),

            }
        },
        Upush: { screen: Upush,
            navigationOptions: {
                tabBarLabel: '推送',
                tabBarIcon: ({tintColor}) => (
                    <Image
                        source={require('./../images/push.png')}
                        style={[{tintColor: tintColor},styles.icon]}
                    />
                ),

            }
        },
        UShare: { screen: UShare,
            navigationOptions: {
                tabBarLabel: '分享',
                tabBarIcon: ({tintColor}) => (
                    <Image
                        source={require('./../images/share.png')}
                        style={[{tintColor: tintColor},styles.icon]}
                    />
                ),

            }
        },

    },
    {
        animationEnabled: true, // 切换页面时是否有动画效果
        tabBarPosition: 'bottom', // 显示在底端，android 默认是显示在页面顶端的
        swipeEnabled: true, // 是否可以左右滑动切换tab
        backBehavior: 'none', // 按 back 键是否跳转到第一个Tab(首页)， none 为不跳转
        tabBarOptions: {
            activeTintColor: ColorUtil.default_primary_color, // 文字和图片选中颜色
            inactiveTintColor: ColorUtil.divider_color, // 文字和图片未选中颜色
            showIcon: true, // android 默认不显示 icon, 需要设置为 true 才会显示
            indicatorStyle: {
                height: 0  // 如TabBar下面显示有一条线，可以设高度为0后隐藏
            },
            style: {
                backgroundColor: ColorUtil.text_primary_color, // TabBar 背景色
                // height: 44
            },
            labelStyle: {
                fontSize: 10, // 文字大小
            },
        },
    });
const styles = StyleSheet.create({
    icon: {
        width: 26,
        height: 26,
    },
});
export default Home;