import type { CollectionConfig } from 'payload'

import { authenticated } from '../../access/authenticated'

export const Users: CollectionConfig = {
  slug: 'users',
  access: {
    admin: authenticated,
    create: authenticated,
    delete: authenticated,
    read: authenticated,
    update: authenticated,
  },
  admin: {
    defaultColumns: ['name', 'email'],
    useAsTitle: 'name',
  },
  auth: true,
  fields: [
    {
      name: 'name',
      type: 'text',
      required: true,
    },
    {
      name: 'email',
      type: 'email',
      required: true,
    },
    {
      name:'plan',
      type:'select',
      options:[
        {
          label:'Free',
          value:'free',
        },
        {
          label:'Storyborn',
          value:'storyborn',
        },
        {
          label:'Dreamborn',
          value:'dreamborn',
        },
      ],
    },
    {
      name:'notificationsPreferences',
      type:'group',
      fields:[
        {
          name:'email',
          type:'checkbox',
          defaultValue:true,
        },
        {
          name:'discord',
          type:'checkbox',
          defaultValue:false,
        },
        {
          name:'telegram',
          type:'checkbox',
          defaultValue:false,
        }
      ],
    },
  ],
  timestamps: true,
}
