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

export default class UserCenter extends Component {


    render() {
        const { navigate } = this.props.navigation;
        return (
            <View style={styles.u_c}>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'关卡开始'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'关卡失败'}</Text>
                </TouchableOpacity>

                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'关卡通过'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'充值付费'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'购买物品（真实消费）'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'购买物品（虚拟消费）'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'使用物品'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'游戏奖励'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'用户登录'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'用户登出'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'有订单的充值付费'}</Text>
                </TouchableOpacity>
            </View>
        );
    }
}

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

        borderWidth: 1.5,
        shadowOffset: {width: 0, height: 0},
        shadowColor: ColorUtil.default_primary_color,
        shadowOpacity: 1,
        shadowRadius: 5,
        justifyContent: 'center',
        alignItems: 'center',

    },
    u_c_text: {
        fontSize:13,

        color: ColorUtil.text_primary_color
    },
});