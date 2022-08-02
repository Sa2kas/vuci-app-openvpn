<template>
  <div class="openvpn">
    <vuci-form :uci-config="configFile" :key="rerender">
      <vuci-typed-section type="openvpn" :columns="instances.columns">
        <template #name="{ s }">
          <vuci-form-item-dummy :uci-section="s" style="margin-bottom: -10px" name="_name"/>
        </template>
        <template #role="{ s }">
          <vuci-form-item-dummy :uci-section="s" style="margin-bottom: -10px" name="type"/>
        </template>
        <template #status="{ s }">
          {{getStatus(s)}}
        </template>
        <template #enable="{ s }">
          <vuci-form-item-switch :uci-section="s" name="enable" @change="enableDisable" style="margin-bottom: -5px"/>
        </template>
        <template #edit="{ s }">
          <a-button type="primary" size="small" style="margin-right: 5px" @click="edit(s)">{{ $t('Edit') }}</a-button>
          <a-popconfirm @confirm="deleteI(s['.name'])" placement="left" title="Really delete this instance?">
            <a-button type="danger" size="small">{{ $t('Delete') }}</a-button>
          </a-popconfirm>
        </template>
      </vuci-typed-section>
      <template #footer>
        <div class="table-footer">
          <div class="footer-title">
            Add instance
          </div>
          <div style="display: flex; flex-direction: horizontal; justify-content: space-between; text-transform: uppercase;">
            <span style="margin-right: 5px">
              Instance name
            </span>
            <a-input type="text" v-model="name" class="create" style="width: 300px"/>
            <a-select v-model="role" style="font-size: 12px; width: 200px; margin: 0 5px">
              <a-select-option value="server">Server</a-select-option>
              <a-select-option value="client">Client</a-select-option>
            </a-select>
            <a-button @click="handleAdd">Create</a-button>
          </div>
        </div>
      </template>
    </vuci-form>
    <vuci-instance-modal @changed="load" v-if="show" @close="close" :item="item"></vuci-instance-modal>
  </div>
</template>

<script>
import VuciInstanceModal from './instances/vuci-instance-modal.vue'
export default {
  components: { VuciInstanceModal },
  data () {
    return {
      rerender: true,
      configFile: 'openvpn',
      instances: {
        columns: [
          { name: 'name', label: 'Instance name' },
          { name: 'role', label: 'Role' },
          { name: 'status', label: 'Status' },
          { name: 'enable', label: 'Enable/Disable', width: 80 },
          { name: 'edit', label: 'Actions', width: 150 }
        ],
        data: []
      },
      name: '',
      role: '',
      show: false,
      item: {},
      routerLAN: '',
      ubusData: [],
      response: ''
    }
  },
  computed: {
  },
  methods: {
    async load () {
      await this.$uci.load(this.configFile)
      this.reRender()
    },
    enableDisable (self) {
      const enable = self.model === true ? 1 : 0
      this.$uci.set(this.configFile, self.sid, 'enable', enable)
      this.$uci.save().then(() => {
        this.$uci.apply().then(() => {
          this.$message.success(enable ? 'Instance successfully enabled' : 'Instance successfully disabled')
          this.load()
        })
      })
    },
    deleteI (sid) {
      const auth = this.$uci.get('openvpn', sid, '_auth')
      const options = this.filesArray(auth)
      this.$rpc.call('openvpn', 'updateIns', { options: options, sid: sid }).then(() => {
        this.$uci.del(this.configFile, sid)
        this.$uci.save().then(() => {
          this.$uci.apply().then(() => {
            this.load()
          })
        })
      })
    },
    filesArray (auth) {
      const options = []
      const type = this.$uci.get('openvpn', this.item, 'type')
      if (auth === 'tls') {
        options.push('ca', 'cert', 'key')
        if (type === 'server') { options.push('dh') }
        if (type === 'client') { options.push('hmac') }
      }
      if (auth === 'skey') { options.push('secret') }
      return options
    },
    reRender () {
      this.rerender = !this.rerender
    },
    edit (s) {
      this.item = s
      this.show = true
    },
    close () {
      this.show = false
      this.item = {}
      this.getServiceList()
    },
    handleAdd () {
      if (!this.name) {
        this.$message.error('Name cannot be empty')
        return
      }
      if (!this.role) {
        this.$message.error('Need to select role')
        return
      }
      if (this.name.length > 15) {
        this.$message.error('Name is too long')
        return
      }
      const instances = this.$uci.sections(this.configFile, 'openvpn')
      for (let index = 0; index < instances.length; index++) {
        if (instances[index]['.name'] === this.name) {
          this.$message.error('Name already used')
          return
        }
        if (instances[index].type === 'server' && this.role === 'server') {
          this.$message.error('Server instance already exists')
          return
        }
      }
      this.$uci.add(this.configFile, 'openvpn', this.name)
      this.$uci.set(this.configFile, this.name, '_name', `${this.name}_${this.role === 'server' ? 'server' : 'client'}`)
      this.$uci.set(this.configFile, this.name, 'cipher', 'BF-CBC')
      this.$uci.set(this.configFile, this.name, 'persist_key', '1')
      this.$uci.set(this.configFile, this.name, 'port', '1194')
      this.$uci.set(this.configFile, this.name, 'dev', `tun_${this.role === 'server' ? 's' : 'c'}_${this.name}`)
      this.$uci.set(this.configFile, this.name, 'persist_tun', '1')
      this.$uci.set(this.configFile, this.name, 'verb', '5')
      this.$uci.set(this.configFile, this.name, 'type', this.role)
      this.$uci.set(this.configFile, this.name, 'proto', 'udp')
      this.$uci.set(this.configFile, this.name, 'enable', '0')
      this.$uci.set(this.configFile, this.name, 'lzo', 'none')
      switch (this.role) {
        case 'server':
          break
        case 'client':
          this.$uci.set(this.configFile, this.name, 'nobind', '1')
          this.$uci.set(this.configFile, this.name, 'resolv_retry', '0')
          break
      }
      this.$uci.save().then(() => {
        this.$uci.apply().then(() => {
          this.load()
          this.name = ''
          this.role = ''
          this.getServiceList()
          this.$message.success('Instance successfully created')
        })
      })
    },
    getStatus (s) {
      if (s.enable === '0') return 'Disabled'
      switch (s.type) {
        case 'server':
          if (this.ubusData[s._name] == null) return 'Inactive'
          if (s.enable === '1' && this.ubusData[s._name].running) return 'Active'
          else return 'Inactive'
        case 'client':
          if (s.enable === '1' && s.status != null) return 'Connected'
          else return 'Disconnected'
        default:
          return 'Not working'
      }
    },
    getServiceList () {
      this.$rpc.call('ubus', 'call', { object: 'service', method: 'list' }).then(response => {
        if (!response.openvpn.length) {
          this.ubusData = response.openvpn.instances
        }
      })
    }
  },
  created () {
    this.getServiceList()
  }
}
</script>
