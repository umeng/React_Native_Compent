/**
 * Created by wangfei on 17/8/28.
 */
import React, { Component } from 'react';
import {
    AppRegistry,
    StyleSheet,
    Text,
    Button,
    TextInput,
    TouchableOpacity,
    AsyncStorage,
    View
} from 'react-native';
import ColorUtil from './ColorUtil'
import PushUtil from './../native/PushUtil'
export default class UserCenter extends Component {

    constructor(props) {
        super(props);
        this.state = {tag: "Tags/Alias/Excusive Alias",type:"Alias Type",result:"结果"};
    }
    addtag(){
        PushUtil.addTag(this.state.tag,(code, remain) =>{
            if (code == 200){
                this.setState({result:remain});
            }
        })
    }
    deleteTag(){
        PushUtil.deleteTag(this.state.tag,(code, remain) =>{
            if (code == 200){
                this.setState({result:remain});
            }
        })
    }
    listTag(){
        PushUtil.listTag((code,tagList) =>{
                if (code == 200){
                var tags="tags:";
                console.log("xxxxxx length="+tagList.length)
                for(var i=0;i<tagList.length;i++){
                    tags = tags+tagList[i]+"\n";
                    console.log("xxxxxx tags="+tags)
                }
                this.setState({result:tags});
                }
        })
    }
    addAlias(){
        PushUtil.addAlias(this.state.tag,"UMENG",(code) =>{
            if (code == 200){
                this.setState({result:code});
            }
        })
    }
    addExclusiveAlias(){
        PushUtil.addExclusiveAlias(this.state.tag,"UMENG",(code) =>{
            if (code == 200){
                this.setState({result:code});
            }
        })
    }
    deleteAlias(){
        PushUtil.deleteAlias(this.state.tag,"UMENG",(code) =>{
            if (code == 200){
                this.setState({result:code});
            }
        })
    }

    render() {
        const { navigate } = this.props.navigation;
        return (
            <View style={styles.u_c}>
                <Text>{this.state.result}</Text>
                <TextInput
                    style={{height: 40, borderColor: 'gray', borderWidth: 1}}
                    onChangeText={(text) => this.setState({tag:text})}
                    value={this.state.tag}
                />
                <TextInput
                    style={{height: 40, borderColor: 'gray', borderWidth: 1}}
                    onChangeText={(text) => this.setState({type:text})}
                    value={this.state.type}
                />
                <View style = {{flexDirection: 'row'}}>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.addtag.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'ADD TAGS'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.deleteTag.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'DELE TAGS'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.listTag.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'LIST TAGS'}</Text>
                    </TouchableOpacity>
                </View>
                <View style = {{flexDirection: 'row'}}>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.addAlias.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'ADD ALIAS'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.addExclusiveAlias.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'ADD EXCLUSIVE ALIAS'}</Text>
                    </TouchableOpacity>
                </View>
                <View style = {{flexDirection: 'row'}}>
                    <TouchableOpacity
                        style={styles.u_c_item}
                        onPress={this.deleteAlias.bind(this)}
                    >
                        <Text style={styles.u_c_text}>{'DEL ALIAS'}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.u_c_item}

                    >
                        <Text style={styles.u_c_text}>{'SERIALNET'}</Text>
                    </TouchableOpacity>
                </View>
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