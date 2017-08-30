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
import AnalyticsUtil from './../native/AnalyticsUtil'
export default class UserCenter extends Component {

    startLevel(){
        AnalyticsUtil.startLevel("1");
    }
    failLevel(){
        AnalyticsUtil.failLevel("1");
    }
    finishLevel(){
        AnalyticsUtil.finishLevel("1");
    }
    pay(){
        AnalyticsUtil.pay(10, 2000, 2);
    }
    payWithItem(){
        AnalyticsUtil.payWithItem(10, "sword", 1, 1000, 2);
    }
    buy(){
        AnalyticsUtil.buy("magic", 2, 100);
    }
    use(){
        AnalyticsUtil.use("magic", 1, 100);
    }
    bonus(){
        AnalyticsUtil.bonus(1000, 2);
        AnalyticsUtil.bonusWithItem("sword", 1, 100, 2);
    }
    exchange(){
        AnalyticsUtil.exchange(88.88, "USD", 10000, 2, "test-ordedid");
    }
    render() {
        const { navigate } = this.props.navigation;
        return (
            <View style={styles.u_c}>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.startLevel.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'关卡开始'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.failLevel.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'关卡失败'}</Text>
                </TouchableOpacity>

                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.failLevel.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'关卡通过'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.pay.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'充值付费'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.payWithItem.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'购买物品（真实消费）'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.failLevel.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'购买物品（虚拟消费）'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.use.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'使用物品'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.bonus.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'游戏奖励'}</Text>
                </TouchableOpacity>

                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.exchange.bind(this)}
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
        fontSize:18,

        color: ColorUtil.text_primary_color
    },
});