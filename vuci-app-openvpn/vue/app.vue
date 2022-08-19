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
          <a-popconfirm @confirm="del(s['.name'], s)" placement="left" title="Are you sure you want to delete this instance?">
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
    del (sid, item) {
      console.log(item)
      return this.$rpc.call('openvpn', 'deleteInstance', { item: item }).then(() => {
        this.$uci.del(this.configFile, sid)
        this.$uci.save().then(() => {
          this.$uci.apply().then(() => {
            this.load()
          })
        })
      })
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
    validateName () {
      if (!this.name) {
        return 'Name cannot be empty'
      }
      if (!this.role) {
        return 'Need to select role'
      }
      if (this.name.length > 15) {
        return 'Name is too long'
      }
      const instances = this.$uci.sections(this.configFile, 'openvpn')
      for (let index = 0; index < instances.length; index++) {
        if (instances[index]['.name'] === this.name) {
          return 'Name already used'
        }
        if (instances[index].type === 'server' && this.role === 'server') {
          return 'Server instance already exists'
        }
      }
    },
    handleAdd () {
      if (this.validateName) {
        this.$message.error(this.validateName)
        return
      }
      this.$uci.add(this.configFile, 'openvpn', this.name)
      this.$uci.set(this.configFile, this.name, '_name', `${this.name}_${this.role === 'server' ? 'server' : 'client'}`)
      this.$uci.set(this.configFile, this.name, 'type', this.role)
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
          if (this.ubusData) {
            if (!this.ubusData[s._name]) return 'Inactive'
            if (s.enable === '1' && this.ubusData[s._name].running) return 'Active'
          } else return 'Inactive'
          break
        case 'client':
          if (s.enable === '1' && s.status) return 'Connected'
          else return 'Disconnected'
        default:
          return 'Inactive'
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
<style>

</style>
