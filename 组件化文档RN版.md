# 工程配置
## Android
### 初始化
## iOS
### 初始化
## 接口说明
# 统计
## Android
### 初始化
## iOS
### 初始化
## 接口说明
# 推送
## Android
### 初始化
## iOS
### 初始化
## 接口说明
首先需要引入`PushUtil`文件：

```
import PushUtil from './PushUtil'
```
### 添加tag
```
 PushUtil.addTag(tag,(code,result) =>{
            
        })
```
* tag 此参数为tag
* callback 第一个参数code为错误码，当为0时标记成功。result为一个字典类型，对照如下：

| key | value|
| -------- | -------- | 
| status     | 0     | 
| remain     | 1     | 
| interval     | 2     | 
| errors     | 3     | 
| last_requestTime     | 4     | 
| jsonString     | 5     | 

### 删除tag
```
  PushUtil.deleteTag(tag,(code,result) =>{
          
        })
```
* tag 此参数为tag
* callback 第一个参数code为错误码，当为0时标记成功。result为一个字典类型，属性请参照添加tag
### 展示tag
```
  PushUtil.listTag((code,result) =>{
            
        })
```

* callback 第一个参数code为错误码，当为0时标记成功。result为一个数组类型，内容为所有tag

### 添加Alias
```
PushUtil.addAlias(alias,type,(code,result) =>{
          
        })
```
* alias 此参数为alias
* type  此参数为alias type
* callback 第一个参数code为错误码，当为0时标记成功。result为一个字符串类型，标记结果
### 添加额外Alias
```
PushUtil.addExclusiveAlias(alias,type,(code,result) =>{
          
        })
```
* alias 此参数为alias
* type  此参数为alias type
* callback 第一个参数code为错误码，当为0时标记成功。result为一个字符串类型，标记结果
### 删除Alias
```
PushUtil.deleteAlias(alias,type,(code,result) =>{
          
        })
```
* alias 此参数为alias
* type  此参数为alias type
* callback 第一个参数code为错误码，当为0时标记成功。result为一个字符串类型，标记结果
### appinfo
```
PushUtil.appInfo((result) =>{

        })
```
* callback result为一个字符串类型，标记结果

# Share
## Android
### 初始化
## iOS
### 初始化
## 接口说明
首先需要引入`ShareUtil`文件：

```
import ShareUtile from './ShareUtil'
```
### 授权

授权代码可以直接使用`ShareUtile.auth(platform,callback)`，其中platform为平台id，callback为回调内容。
平台与id的对应关系如下：


| 平台 | id|
| -------- | -------- | 
| QQ     | 0     | 
| 新浪微博     | 1     | 
| 微信     | 2     | 
| 微信朋友圈     | 3     | 
| Qzone     | 4     | 
| 电子邮件     | 5     | 
| 短信     | 6     | 
| Facebook     | 7     | 
| Twitter     | 8     | 

回调示例如下：

```
  ShareUtile.auth(0,(code,result,message) =>{
            this.setState({result:message});
            if (code == 0){
                this.setState({result:result.uid});
            }
        });
```
其中code为错误码，当为0时标记为成功。
其中message为错误信息。
其中result属性如下：

| 属性 | 含义|
| -------- | -------- | 
| uid     | uid     | 
| screen_name     | 用户名     | 
| iconurl     | 头像     | 
| accessToken     | accessToken     | 
| refreshToken     | refreshToken| 
| gender     | gender     | 
| unionid     | unionid     | 
| openid     | openid     | 
| expires_in     | 过期时间     | 

### 分享
分享示例如下：

```
 ShareUtile.share(text,img,url,title,platform,(code,message) =>{
            this.setState({result:message});

        });
```

* text 为分享内容
* img 为图片地址，可以为链接，本地地址以及res图片（如果使用res,请使用如下写法：`res/icon.png`）
* url 为分享链接，可以为空
* title 为分享链接的标题
* platform为平台id，id对照表与授权相同
* callback中code为错误码，当为0时，标记成功。message为错误信息
### 分享面板
分享面板示例如下：

```
 ShareUtile.shareboard(text,img,url,title,list,(code,message) =>{
            this.setState({result:message});

        });
```

* text 为分享内容
* img 为图片地址，可以为链接，本地地址以及res图片（如果使用res,请使用如下写法：`res/icon.png`）
* url 为分享链接，可以为空
* title 为分享链接的标题
* list 为分享平台数组，如：` var list = [0,1,2]`
* callback中code为错误码，当为0时，标记成功。message为错误信息
