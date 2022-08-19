
# vuci-app-openvpn

**Note:**  The application is created for educational purposes, so names of UCI options in the configuration file may differ from the required ones


### Updates

Updated VuciFormItemMixin.vue file and created additional vuci-form-item attribute

#### VuciFormItemMixin.vue
Added code
```javascript
    // ------------------- Created additional attribute ---------------------
    // If there is no set value, the value of the property is used as default
    defaultValue: [String, Number, Array]
    // ----------------------------------------------------------------------
```
Updated __save method
```javascript
    __save () {
      if (this.model === '' && this.initial) {
        this.model = this.initial
        return
      }
      // -------------------------- Added code ---------------------------
      if (typeof this.model === 'undefined' && this.defaultValue) {
        this.$uci.set(this.config, this.sid, this.name, this.defaultValue)
      }
      // -----------------------------------------------------------------

      if (this.changed()) {
        if (this.save) { return this.save(this) }
        this.$uci.set(this.config, this.sid, this.name, this.model)
      }
    },
```

#### Additional attribute
Used to set default UCI option value

| Name         | Description              | Type                | Default  |
| :----------- | :----------------------- | :------------------ | :------- |
| defaultValue | default UCI option value | string/number/array | -        |



