
const eventArgsOf = (r,name)  => {
    for (let i=0;i<r.logs.length;i++) {
      if (r.logs[i].event==name) return r.logs[i].args;
    }
    throw "Event "+name+" not found"
  }

module.exports = eventArgsOf
