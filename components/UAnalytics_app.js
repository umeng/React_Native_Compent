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
                <View style = {{flexDirection: 'row'}}>
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

                </View>
                <View style = {{flexDirection: 'row'}}>
                    <TouchableOpacity
                        style={styles.u_c_item}
                    >
                        <Text style={styles.u_c_text}>{'普通事件'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}
                    >
                        <Text style={styles.u_c_text}>{'多属性事件'}</Text>
                    </TouchableOpacity>

                </View>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'数值性统计'}</Text>
                </TouchableOpacity>

                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'程序崩溃'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'Webview统计'}</Text>
                </TouchableOpacity>
                <View style = {{flexDirection: 'row'}}>
                    <TouchableOpacity
                        style={styles.u_c_item}
                    >
                        <Text style={styles.u_c_text}>{'track事件'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}
                    >
                        <Text style={styles.u_c_text}>{'自定义track事件'}</Text>
                    </TouchableOpacity>

                </View>
                <View style = {{flexDirection: 'row'}}>
                    <TouchableOpacity
                        style={styles.u_c_item}
                    >
                        <Text style={styles.u_c_text}>{'设置超级属性'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}
                    >
                        <Text style={styles.u_c_text}>{'获取超级属性'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}
                    >
                        <Text style={styles.u_c_text}>{'清除超级属性'}</Text>
                    </TouchableOpacity>

                </View>
                <TouchableOpacity
                    style={styles.u_c_item}
                >
                    <Text style={styles.u_c_text}>{'关注首次触发事件'}</Text>
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