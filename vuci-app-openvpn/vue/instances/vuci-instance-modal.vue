<template>
  <div class="instance-modal">
    <a-modal class="i-modal" :title="item._name" v-model="show" :afterClose="close" :footer="null">
      <div style="display: block;">
        <a-checkbox style="margin-bottom: 20px;" @change="reRender" v-model="advanced">Advanced</a-checkbox>
      </div>
      <vuci-form uci-config="openvpn" :key="rerender" @applied="changeAuthFiles">
        <vuci-named-section class="instance-modal-form" :name="item['.name']" :card="false" v-slot="{ s }" @change-_auth="authChange">
          <vuci-form-item-switch :uci-section="s" label="Enable" name="enable" defaultValue="0"/>
          <vuci-form-item-select :uci-section="s" label="Authentication" name="_auth" :options="auth"/>
          <vuci-form-item-select v-show="advanced" :uci-section="s" label="TUN/TAP" name="tuntap" :options="tunTap" defaultValue="tun"/>
          <vuci-form-item-select v-show="advanced" :uci-section="s" label="Protocol" name="proto" :options="protocols" defaultValue="udp"/>
          <vuci-form-item-input v-show="advanced" :uci-section="s" label="Port" name="port" rules="port" defaultValue="1194"/>
          <vuci-form-item-select v-show="advanced" :uci-section="s" label="LZO" name="lzo" :options="lzo" defaultValue="none"/>
          <vuci-form-item-select v-show="advanced" :uci-section="s" label="Encryption" name="cipher" :options="encryption" defaultValue="BF-CBC"/>
          <vuci-form-item-input v-show="advanced" :uci-section="s" label="Keep alive" name="keepalive" :rules="validateKeepAlive" defaultValue="10 120"/>
          <vuci-form-item-select v-show="advanced" :uci-section="s" label="Resolve retry" name="resolv_retry" :options="resolveRetry" v-if="s.type === 'client'" defaultValue="infinite"/>
          <vuci-form-item-input :uci-section="s" label="Remote host/IP address" name="remote" rules="ip4addr" v-if="s.type == 'client'"/>
          <vuci-form-item-input :uci-section="s" label="Remote network IP address" name="network_ip" @change="setRemoteIp" rules="ip4addr" v-if="s.type == 'client'"/>
          <vuci-form-item-input :uci-section="s" label="Remote network netmask" name="network_mask" :rules="validateNetMask" v-if="s.type == 'client'"/>
          <vuci-form-item-input :uci-section="s" label="Local tunnel endpoint IP" name="local_ip" rules="ip4addr" depend="_auth == 'skey'"/>
          <vuci-form-item-input :uci-section="s" label="Remote tunnel endpoint IP" name="remote_ip" :rules="'ip4addr'" depend="_auth == 'skey'"/>
          <vuci-form-item-input :uci-section="s" label="Remote network IP address" name="network_ip" @change="setRemoteIp" rules="ip4addr" v-if="s.type == 'server'" depend="_auth == 'skey'"/>
          <vuci-form-item-input :uci-section="s" label="Remote network netmask" name="network_mask" :rules="validateNetMask" v-if="s.type == 'server'" depend="_auth == 'skey'"/>
          <vuci-form-item :uci-section="s" label="Static key" name="secret" depend="_auth == 'skey'">
            <a-upload :before-upload="self => beforeUpload(self, 'secret')" :maxCount="1">
              <a-button size="small" type="primary" icon="upload">Select file</a-button>
            </a-upload>
            <span style="margin-left: 5px">{{showFileName('secret') || 'no file uploaded'}}</span>
          </vuci-form-item>
          <vuci-form-item-select v-show="advanced" :uci-section="s" label="TLS cipher" name="tls_cipher" depend="_auth == 'tls'" :options="tlsCiphers" allow-create defaultValue="all"/>
          <vuci-form-item-select v-show="advanced" :uci-section="s" label="Allowed TLS ciphers" name="allowed_ciphers" depend="_auth == 'tls'" :options="tlsCiphers" allow-create defaultValue="all"/>
          <span v-if="item.type == 'client'">
            <vuci-form-item-select v-show="advanced" :uci-section="s" label="HMAC authentication algorithm" name="auth" :options="hmac" depend="_auth == 'tls'" defaultValue="sha1"/>
            <vuci-form-item-switch v-show="advanced" :uci-section="s" label="Additional HMAC authentication" name="hmac_auth" depend="_auth == 'tls'" defaultValue="0"/>
            <vuci-form-item-switch v-show="advanced" :uci-section="s" label="HMAC key direction" name="hmac_key_dir" depend="_auth == 'tls'" defaultValue="1"/>
            <vuci-form-item-input v-show="advanced" :uci-section="s" label="Private key decryption password" name="dec_pwd" depend="_auth == 'tls'"/>
            <vuci-form-item :uci-section="s" name="ca" label="Certificate authority" depend="_auth == 'tls'">
              <a-upload :before-upload="self => beforeUpload(self, 'ca')" :maxCount="1">
                <a-button size="small" type="primary" icon="upload">Select file</a-button>
              </a-upload>
              <span style="margin-left: 5px">{{showFileName('ca') || 'no file uploaded'}}</span>
            </vuci-form-item>
            <vuci-form-item :uci-section="s" name="cert" label="Client certificate" depend="_auth == 'tls'">
              <a-upload action="/upload" :before-upload="self => beforeUpload(self, 'clientCert')" :max-count="1">
                <a-button size="small" type="primary" icon="upload">Select file</a-button>
              </a-upload>
              <span style="margin-left: 5px">{{showFileName('clientCert') || 'no file uploaded'}}</span>
            </vuci-form-item>
            <vuci-form-item :uci-section="s" name="key" label="Client key" depend="_auth == 'tls'">
              <a-upload action="/upload" :before-upload="self => beforeUpload(self, 'clientKey')" :maxCount="1">
                <a-button size="small" type="primary" icon="upload">Select file</a-button>
              </a-upload>
              <span style="margin-left: 5px">{{showFileName('clientKey') || 'no file uploaded'}}</span>
            </vuci-form-item>
          </span>
          <!-- SERVER TLS -->
          <span v-if="item.type == 'server'">
            <vuci-form-item-input :uci-section="s" label="Virtual network IP address" name="server_ip" rules="ip4addr" depend="_auth == 'tls'"/>
            <vuci-form-item-input :uci-section="s" label="Virtual network netmask" name="server_netmask" rules="ip4addr" depend="_auth == 'tls'" defaultValue="0"/>
            <vuci-form-item-switch v-show="advanced" :uci-section="s" label="Client to client" name="client_to_client" depend="_auth == 'tls'" defaultValue="0"/>
            <vuci-form-item-switch v-show="advanced" :uci-section="s" label="Allow duplicate certificates" name="cert_dublicate" depend="_auth == 'tls'"/>
            <vuci-form-item :uci-section="s" label="Certificate authority certificate" depend="_auth == 'tls'" name="ca">
              <a-upload action="/upload" :before-upload="self => beforeUpload(self, 'ca')" :maxCount="1">
                <a-button size="small" type="primary" icon="upload">Select file</a-button>
              </a-upload>
              <span style="margin-left: 5px">{{showFileName('ca') || 'no file uploaded'}}</span>
            </vuci-form-item>
            <vuci-form-item :uci-section="s" name="cert" label="Server certificate" depend="_auth == 'tls'">
              <a-upload action="/upload" :before-upload="self => beforeUpload(self, 'serverCert')" :maxCount="1">
                <a-button size="small" type="primary" icon="upload">Select file</a-button>
              </a-upload>
              <span style="margin-left: 5px">{{showFileName('serverCert') || 'no file uploaded'}}</span>
            </vuci-form-item>
            <vuci-form-item :uci-section="s" name="key" label="Server key" depend="_auth == 'tls'">
              <a-upload action="/upload" :before-upload="self => beforeUpload(self, 'serverKey')" :maxCount="1">
                <a-button size="small" type="primary" icon="upload">Select file</a-button>
              </a-upload>
              <span style="margin-left: 5px">{{showFileName('serverKey') || 'no file uploaded'}}</span>
            </vuci-form-item>
            <vuci-form-item :uci-section="s" name="dh" label="Diffie Hellman parameters file" depend="_auth == 'tls'">
              <a-upload action="/upload" :before-upload="self => beforeUpload(self, 'dh')" :maxCount="1">
                <a-button size="small" type="primary" icon="upload">Select file</a-button>
              </a-upload>
              <span style="margin-left: 5px">{{showFileName('dh') || 'no file uploaded'}}</span>
            </vuci-form-item>
          </span>
        </vuci-named-section>
        <div class="line" style="margin-bottom: 10px margin-left: -24px width: calc(100% + 48px)"/>
      </vuci-form>
    </a-modal>
  </div>
</template>
<script>
import axios from 'axios'
import validator from '@/plugins/vuci-validator'
export default {
  data () {
    return {
      show: true,
      rerender: true,
      form: {},
      auth: [
        ['skey', 'Static Key'],
        ['tls', 'TLS']
      ],
      tunTap: [
        ['tun', 'TUN (tunnel)'],
        ['tap', 'TAP (bridged)']
      ],
      protocols: [
        ['udp', 'UDP'],
        ['tcp', 'TCP'],
        ['udp6', 'UDP6'],
        ['tcp6', 'TCP6']
      ],
      lzo: [
        ['yes', 'Yes'],
        ['no', 'No'],
        ['none', 'None']
      ],
      encryption: [
        ['DES-CBC', 'DES-CBC 64'],
        ['RC2-CBC', 'RC2-CBC 128'],
        ['DES-EDE-CBC', 'DES-EDE-CBC 128'],
        ['DES-EDE3-CBC', 'DES-EDE3-CBC 192'],
        ['DESX-CBC', 'DESX-CBC 192'],
        ['BF-CBC', 'BF-CBC 128'],
        ['RC2-40-CBC', 'RC2-40-CBC 40'],
        ['CAST5-CBC', 'CAST5-CBC 128'],
        ['RC2-40CBC', 'RC2-40CBC 40'],
        ['AES-128-CBC', 'AES-128-CBC 128'],
        ['AES-192-CBC', 'AES-128-CBC 192'],
        ['AES-256-CBC', 'AES-128-CBC 256'],
        ['none', 'None']
      ],
      tlsCiphers: [
        ['all', 'All'],
        ['DHE+RSA', 'DHE+RSA']
      ],
      resolveRetry: [
        ['0', '0'],
        ['infinite', 'Infinite']
      ],
      hmac: [
        ['none', 'None'],
        ['sha1', 'SHA1'],
        ['sha256', 'SHA256'],
        ['sha384', 'SHA384'],
        ['sha512', 'SHA512']
      ],
      fileData: {
        secret: { key: 'secret', value: '.secretstatic.key' },
        ca: { key: 'ca', value: '.caca.cert.pem' },
        clientCert: { key: 'cert', value: '.certclient.cert.pem' },
        clientKey: { key: 'key', value: '.keyclient.key.pem' },
        serverCert: { key: 'cert', value: '.certserver.cert.pem' },
        serverKey: { key: 'key', value: '.keyserver.key.pem' },
        dh: { key: 'dh', value: '.dhdh.pem' }
      },
      remoteIp: '',
      selectedAuth: this.item._auth,
      routerLanAddress: '',
      pathNew: '/etc/vuci-upload/openvpn/',
      fileList: [],
      advanced: false
    }
  },
  props: {
    item: {
      type: Object,
      required: false
    }
  },
  methods: {
    setRemoteIp (self) {
      this.remoteIp = self.model
    },
    changed () {
      this.$emit('changed')
    },
    filePath (name) {
      return `${this.pathNew}cbid.openvpn.${this.item['.name']}${this.fileData[name].value}`
    },
    setList (newFile, newPath) {
      var newValue = 0
      this.fileList.forEach(element => {
        if (element.path === newPath) {
          element.file = newFile
          newValue = 1
        }
      })
      if (!newValue) {
        this.fileList.push({ file: newFile, path: newPath })
      }
    },
    showFileName (value) {
      var name = /[^/]*$/.exec(this.$uci.get('openvpn', this.item['.name'], value) || '')[0]
      return name
    },
    setFilePath (key, path) {
      this.$uci.set('openvpn', this.item['.name'], key, path)
    },
    beforeUpload (file, name) {
      const path = this.filePath(name)
      this.setList(file, path)
      this.setFilePath(this.fileData[name].key, path)
      return false
    },
    async handleUpload () {
      this.fileList.forEach(file => {
        const formData = new FormData()
        formData.append('path', file.path)
        formData.append('file', file.file)
        axios.post('/upload', formData, { 'Content-Type': 'multipart/form-data' })
      })
    },
    authChange (value) {
      this.selectedAuth = value.model
      this.$uci.set('openvpn', this.item['.name'], '_auth', value.model)
      const type = this.$uci.get('openvpn', this.item['.name'], 'type')
      if (value.model === 'skey') {
        this.$uci.set('openvpn', this.item['.name'], 'tls_cipher')
        this.$uci.set('openvpn', this.item['.name'], 'allowed_ciphers')
        if (type === 'client') {
          this.$uci.set('openvpn', this.item['.name'], 'auth')
          this.$uci.set('openvpn', this.item['.name'], 'tls_client')
          this.$uci.set('openvpn', this.item['.name'], 'client')
          this.$uci.set('openvpn', this.item['.name'], 'dec_pwd')
        } else {
          this.$uci.set('openvpn', this.item['.name'], 'tls_server')
          this.$uci.set('openvpn', this.item['.name'], 'server_ip')
          this.$uci.set('openvpn', this.item['.name'], 'server_netmask')
        }
      } else if (value.model === 'tls') {
        this.$uci.set('openvpn', this.item['.name'], 'local_ip')
        this.$uci.set('openvpn', this.item['.name'], 'remote_ip')
        if (type === 'server') {
          this.$uci.set('openvpn', this.item['.name'], 'cert_dublicate')
          this.$uci.set('openvpn', this.item['.name'], 'client_to_client')
        }
      }
    },
    validateNetMask (value) {
      if (!validator.netmask4(value)) {
        return 'Netmask is invalid!'
      }
      if (this.remoteIp == null || this.remoteIp === '') {
        return ''
      }
      if ((this.ip2int(this.routerLanAddress) & value) !== (this.ip2int(this.remoteIp) & value)) {
        return 'Netmask is in incorrect size!'
      }
    },
    validateNetIp (value) {
      console.log(value)
      if (!validator.ip4addr(value)) {
        return 'IP is invalid!'
      }
      if (value === this.routerLanAddress) {
        return 'Cannot be same as LAN address'
      }
    },
    validateKeepAlive (value) {
      if (!value.match(/^[0-9]+\s[0-9]+$/)) return 'Must be two integers separated by a space'
    },
    ip2int (ip) {
      return ip.split('.').reduce((ipInt, octet) => ((ipInt << 8) + parseInt(octet, 10)), 0) >>> 0
    },
    reRender () {
      this.rerender = !this.rerender
    },
    close: function () {
      this.$emit('close')
    },
    fileExists (file) {
      return this[file]
    },
    async changeAuthFiles () {
      await this.handleUpload()
      const auth = this.$uci.get('openvpn', this.item['.name'], '_auth')
      const options = this.optionsArray(auth)
      this.$rpc.call('openvpn', 'updateIns', { options: options, sid: this.item['.name'] }).then(() => {
        this.reRender()
        this.changed()
        this.fileList = []
      })
    },
    optionsArray (auth) {
      const options = []
      const type = this.$uci.get('openvpn', this.item, 'type')
      if (auth === 'skey') {
        options.push('ca', 'cert', 'key')
        if (type === 'server') { options.push('dh') }
      }
      if (auth === 'tls') { options.push('secret') }
      return options
    }
  },
  mounted () {
    this.$network.load().then(() => {
      this.routerLanAddress = this.$network.getInterface('lan').status['ipv4-address'][0].address
    })
    this.reRender()
  }
}
</script>
<style>
  .instance-modal-form > * > .ant-form-item-label,
   .instance-modal-form > span > * > .ant-form-item-label {
    width: 40%;
    text-align: left;
  }
  .i-modal > * > .ant-modal {
    width: 600px !important;
  }
</style>
