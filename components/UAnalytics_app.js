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

    componentWillMount(){
        console.log("aaa componentWillMount");
    }
    componentWillUnmount(){
        console.log("aaa componentWillUnmount");
    }
    profileSignInWithPUID(){
        AnalyticsUtil.profileSignInWithPUID("myname");
    }
    profileSignOff(){
        AnalyticsUtil.profileSignOff()
    }
    onEvent(){
        AnalyticsUtil.onEvent("eventname");
    }
    onEventWithLable(){
        AnalyticsUtil.onEventWithLable("eventname","label");
    }
    onEventWithMap(){
        AnalyticsUtil.onEventWithMap("eventname",{name:"umeng",sex:"man"});
    }
    onEventWithMapAndCount(){
        AnalyticsUtil.onEventWithMapAndCount("eventname",{name:"umeng",sex:"man"},100);
    }
    onTrack(){
        AnalyticsUtil.track("trackname");
    }
    onTrackWithMap(){
        AnalyticsUtil.trackWithMap("trackname",{name:"umeng",sex:"man"});
    }
    registerSuperProperty(){
        AnalyticsUtil.registerSuperProperty({name:"umeng",sex:"man"});
    }
    getSuperProperty(){
        AnalyticsUtil.getSuperProperties((result) =>{
           console.log(result)
        });
    }
    clearSuperProperties(){
        AnalyticsUtil.clearSuperProperties();
    }
    setFirstLaunchEvent(){
        AnalyticsUtil.setFirstLaunchEvent(["111","222","333"]);
    }
    render() {
        const { navigate } = this.props.navigation;
        return (
            <View style={styles.u_c}>
                <View style = {{flexDirection: 'row'}}>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.profileSignInWithPUID.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'用户登录'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.profileSignOff.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'用户登出'}</Text>
                    </TouchableOpacity>

                </View>
                <View style = {{flexDirection: 'row'}}>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.onEvent.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'普通事件'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.onEventWithMap.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'多属性事件'}</Text>
                    </TouchableOpacity>

                </View>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.onEventWithMapAndCount.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'数值性统计'}</Text>
                </TouchableOpacity>



                <View style = {{flexDirection: 'row'}}>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.onTrack.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'track事件'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.onTrackWithMap.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'自定义track事件'}</Text>
                    </TouchableOpacity>

                </View>
                <View style = {{flexDirection: 'row'}}>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.registerSuperProperty.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'设置超级属性'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.getSuperProperty.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'获取超级属性'}</Text>
                    </TouchableOpacity>


                </View>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.clearSuperProperties.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'清除超级属性'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.setFirstLaunchEvent.bind(this)}
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
        fontSize:24,

        color: ColorUtil.text_primary_color
    },
});