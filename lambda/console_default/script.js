function UpdateStartButton(state) {
    let button = document.getElementById("start");
    if (button) { button.disabled = state; }
    let admin_button = document.getElementById("admin_start");
    if (admin_button) { admin_button.disabled = state; }
}

function Describe() {
    let sender = document.querySelector("#describe-form");
    UpdateStartButton(true);
    document.querySelector("#result2").innerHTML = '<p>インスタンス情報確認中...<div class="loader"></div></p>';
    XMLHttpRequestSubmit(sender).then((xhr) => {
        let div = document.querySelector("#result2");
        if (xhr.readyState == 4 && xhr.status == 200) {
            let instances = xhr.response.instances;
            for (let i = 0; i < instances.length; ++i) {
                let instance = instances[i];
                if (instance.State != 'running') { continue; }
                if (!instance.PublicIpAddress) { continue; }

                div.innerHTML = '<p>インスタンスへの接続を開始します...<div class="loader"></div></p>';
                RedirectInstancePage(instance.PublicIpAddress);
                return;
            }
            div.innerHTML = '<p>インスタンスが存在しません。サーバーを起動してください。</p>';
            UpdateStartButton(false);
        } else {
            div.innerHTML = '<p>インスタンスの確認に失敗しました。ページをリロードしてください。</p>';
            UpdateStartButton(false);
        }
    });
}

function ListArchive() {
    let sender = document.querySelector("#list-archive-form");
    document.querySelector("#archives").innerHTML = '<p>ロード中...<div class="loader"></div></p>';
    XMLHttpRequestSubmit(sender).then((xhr) => {
        let div = document.querySelector("#archives");
        if (xhr.readyState == 4 && xhr.status == 200) {
            let archives = xhr.response.archives;
            let storage_class_index = {
                'STANDARD': 0,
                'REDUCED_REDUNDANCY': 1,
                'GLACIER': 2,
                'STANDARD_IA': 3,
                'ONEZONE_IA': 4,
                'INTELLIGENT_TIERING': 5,
                'DEEP_ARCHIVE': 6,
                'OUTPOSTS': 7,
                'GLACIER_IR': 8,
                'SNOW': 9,
                'EXPRESS_ONEZONE': 10
            }
            archives.sort((a, b) => {
                // ascending by storage class
                const aClassIndex = storage_class_index[a.StorageClass];
                const bClassIndex = storage_class_index[b.StorageClass];
                if (aClassIndex < bClassIndex) { return -1; }
                if (aClassIndex > bClassIndex) { return 1; }

                // descending by replaced key
                const aKey = a.Key.replace(/_/g, "-");
                const bKey = b.Key.replace(/_/g, "-");
                if (aKey < bKey) { return 1; }
                if (aKey > bKey) { return -1; }

                return 0;
            });

            let table = document.createElement("table");
            let thead = document.createElement("thead");
            let tbody = document.createElement("tbody");

            let tr = document.createElement("tr");
            ['アーカイブ名', '更新日時', 'サイズ', 'ストレージクラス'].forEach(value => {
                let th = document.createElement("th");
                th.setAttribute("scope", "col");
                th.innerHTML = value;
                tr.appendChild(th);
            });
            thead.appendChild(tr);

            for (let i = 0; i < archives.length; ++i) {
                tr = document.createElement("tr");
                let archive = archives[i];
                let values = [archive.Key, new Date(archive.LastModified), archive.Size, archive.StorageClass];
                values.forEach(value => {
                    let td = document.createElement("td");
                    td.innerHTML = value;
                    tr.appendChild(td);
                });
                tbody.appendChild(tr);
            }

            table.appendChild(thead);
            table.appendChild(tbody);
            while(div.firstChild) { div.removeChild(div.firstChild); }
            div.appendChild(table);
        } else {
            div.innerHTML = '<p>アーカイブ一覧の取得に失敗しました。</p>';
        }
    });
}

function RedirectInstancePage(publicIpAddress) {
    let sender = document.querySelector("#describe-form");
    UpdateStartButton(true);
    document.querySelector("#result2").innerHTML = '<p>インスタンスへの接続試行中...<div class="loader"></div></p>';
    XMLHttpRequestSubmit(sender).then((xhr) => {
        let div = document.querySelector("#result2");
        if (xhr.readyState == 4 && xhr.status == 200) {
            let instances = xhr.response.instances;
            let instance = null;
            for (let i = 0; i < instances.length; ++i) {
                if (instances[i].PublicIpAddress != publicIpAddress) { continue; }
                instance = instances[i];
                break;
            }
            if (!instance.State) {
                div.innerHTML = '<p>インスタンスが特定できませんでした。ページをリロードしてください。</p>';
                UpdateStartButton(false);
                return;
            }
            if (instance.State != 'running') {
                div.innerHTML = '<p>インスタンスが既に停止しています。ページをリロードしてください。</p>';
                UpdateStartButton(false);
                return;
            }

            if (!instance.HealthCheck) {
                div.innerHTML = '<p>インスタンスの起動を待機中です...<div class="loader"></div></p>';
                setTimeout(function() {
                    RedirectInstancePage(publicIpAddress);
                }, 15 * 1000);
                return;
            }

            div.innerHTML = '<p>インスタンスへ接続します...<div class="loader"></div></p>';
            setTimeout(function() {
                window.location = "http://" + publicIpAddress + ":18080/";
            }, 1 * 1000);
        } else {
            div.innerHTML = '<p>インスタンスへの接続試行に失敗しました。再実行します...<div class="loader"></div></p>';
            setTimeout(function() {
                RedirectInstancePage(publicIpAddress);
            }, 3 * 1000);
        }
    });
}

function Start(sender) {
    UpdateStartButton(true);
    document.querySelector("#result2").innerHTML = '<p>インスタンス作成中...<div class="loader"></div></p>';
    document.querySelector("#parameter-form > #instance_id").removeAttribute("value");
    XMLHttpRequestSubmit(sender).then((xhr) => {
        let div = document.querySelector("#result2");
        if (xhr.readyState == 4 && xhr.status == 200) {
            div.innerHTML = '<p>インスタンスを作成しました。</p>';
            SyncInstanceRuning(sender, xhr.response.InstanceId);
        } else {
            div.innerHTML = '<p>インスタンスの作成に失敗しました。管理者へ確認してください。</p>';
            UpdateStartButton(false);
        }
    });
}

function SyncInstanceRuning(sender, instanceId) {
    UpdateStartButton(true);
    document.querySelector("#result2").innerHTML = '<p>インスタンス起動中...<div class="loader"></div></p>';
    sender.setAttribute("value", "SyncInstanceRuning");
    document.querySelector("#parameter-form > #instance_id").setAttribute("value", instanceId);
    setTimeout(function() {
        XMLHttpRequestSubmit(sender).then((xhr) => {
            let div = document.querySelector("#result2");
            if (xhr.readyState == 4 && xhr.status == 200) {
                div.innerHTML = '<p>インスタンスを起動し、サーバーの初期化を開始しました。</p>';
                setTimeout(() => {
                    Describe();
                }, 5 * 1000);
            } else {
                div.innerHTML = "<p>インスタンスの起動に失敗しました。管理者へ確認してください。</p>";
                UpdateStartButton(false);
            }
        });
    }, 30 * 1000);
}

// cite: https://stackoverflow.com/questions/35902647/how-to-pass-formdata-over-xmlhttprequest-using-get-method
function XMLHttpRequestSubmit(sender) {
    return new Promise((resolve, reject) => {
        var xmlreq = new XMLHttpRequest(), params;
        var sender_original = sender;
        // look around for the sender form and key-value params
        if (sender.form !== undefined)
        {
            params = new FormData(sender.form);
            params.append(sender.name, sender.value);
            sender = sender.form;
        }
        else params = new FormData(sender);
        var actAddress = new URL(sender.baseURI).origin;

        // append the params to the address in action attribute
        if (sender.method == 'get')
        {
            var firstRun = true;
            for (var key of params.keys())
            {
                if (firstRun)
                {
                    actAddress += '?';
                    firstRun = false;
                }
                else actAddress += '&';
                actAddress += key + "=" + params.get(key);
            }
        }

        xmlreq.responseType = "json";
        xmlreq.open(sender.method, actAddress, true);
        xmlreq.onload = () => {
            resolve(xmlreq);
        };
        if (sender.method == 'get')
            xmlreq.send();
        else xmlreq.send(params);
    });
}

window.addEventListener("load", (event) => {
    Describe();
    ListArchive();
});
