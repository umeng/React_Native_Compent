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
import ShareUtile from './../native/ShareUtil'
export default class UserCenter extends Component {

    constructor(props) {
        super(props);
        this.state = {result: "结果"};
    }
    qqauth(){
        ShareUtile.auth(0,(code,result,message) =>{
            this.setState({result:message});
            if (code == 200){
                this.setState({result:result.uid});
            }
        });
    }
    sinaauth(){
        ShareUtile.auth(1,(code,result,message) =>{
            this.setState({result:message});
            if (code == 200){
                this.setState({result:result.uid});
            }
        });
    }
    wxauth(){
        ShareUtile.auth(2,(code,result,message) =>{
            this.setState({result:message});
            if (code == 200){
                this.setState({result:result.uid});
            }
        });
    }
    render() {
        const { navigate } = this.props.navigation;
        return (
            <View style={styles.u_c}>
                <Text>{this.state.result}</Text>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.sinaauth.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'新浪授权'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.wxauth.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'微信授权'}</Text>
                </TouchableOpacity>

                <TouchableOpacity
                    style={styles.u_c_item}
                    onPress={this.qqauth.bind(this)}
                >
                    <Text style={styles.u_c_text}>{'QQ授权'}</Text>
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